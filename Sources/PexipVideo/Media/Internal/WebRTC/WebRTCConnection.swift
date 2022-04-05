import Foundation
import WebRTC
import Combine

final class WebRTCConnection: NSObject, MediaConnection, RTCPeerConnectionDelegate {
    var eventPublisher: AnyPublisher<MediaConnectionEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    private(set) var audioTrack: LocalAudioTrackProtocol?
    private(set) var localVideoTrack: LocalVideoTrackProtocol?
    private(set) var remoteVideoTrack: VideoTrackProtocol?

    private let mediaConstraints: RTCMediaConstraints
    private let features: MediaFeature
    private let factory: RTCPeerConnectionFactory
    private let peerConnection: RTCPeerConnection
    private let logger: CategoryLogger
    private let qualityProfile: QualityProfile
    private var setRemoteVideoTrack: ((RTCVideoTrack) -> Void)?
    private let localStreamId = UUID().uuidString
    private var icePwd: String?
    private let eventSubject = PassthroughSubject<MediaConnectionEvent, Never>()

    // MARK: - Init

    @available(*, unavailable)
    override init() {
        fatalError("WebRTCClient:init is unavailable")
    }

    required init(
        iceServers: [String],
        qualityProfile: QualityProfile,
        features: MediaFeature,
        factory: RTCPeerConnectionFactory = .default,
        logger: CategoryLogger
    ) {
        self.mediaConstraints = .constraints(
            receiveVideo: features.contains(.receiveAudio),
            receiveAudio: features.contains(.receiveVideo)
        )

        guard let peerConnection = factory.peerConnection(
            with: .configuration(withIceServers: iceServers),
            constraints: mediaConstraints,
            delegate: nil
        ) else {
            fatalError("Could not create new RTCPeerConnection")
        }

        self.features = features
        self.factory = factory
        self.peerConnection = peerConnection
        self.logger = logger
        self.qualityProfile = qualityProfile

        super.init()

        self.peerConnection.delegate = self
        setupMedia()
    }

    // MARK: - Setup

    private func setupMedia() {
        if features.contains(.sendAudio) {
            self.audioTrack = WebRTCAudioTrack(
                factory: factory,
                trackManager: peerConnection,
                capturePermission: .audio,
                streamId: localStreamId
            )
        }

        if features.contains(.sendVideo) {
            #if !targetEnvironment(simulator)
            self.localVideoTrack = WebRTCLocalVideoTrack(
                factory: factory,
                trackManager: peerConnection,
                capturePermission: .video,
                qualityProfile: qualityProfile,
                streamId: localStreamId
            )
            #endif
        }

        let remoteVideoTrack = WebRTCVideoTrack(
            track: nil,
            aspectRatio: CGSize(width: 16, height: 9)
        )
        self.setRemoteVideoTrack = {
            remoteVideoTrack.setTrack($0)
        }
        self.remoteVideoTrack = remoteVideoTrack
    }

    // MARK: - Signaling

    func createOffer() async throws -> String {
        let offer = try await peerConnection.offer(for: mediaConstraints)
        icePwd = IceCandidate.pwd(from: offer.sdp)
        try await peerConnection.setLocalDescription(offer)
        return offer.sdp
    }

    func setRemoteDescription(_ sdp: SessionDescription) async throws {
        let description = RTCSessionDescription(type: .answer, sdp: sdp)
        try await peerConnection.setRemoteDescription(description)
    }

    func close() {
        peerConnection.close()
    }

    // MARK: - RTCPeerConnectionDelegate

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        logger.debug("Peer connection - new signaling state: \(stateChanged.debugDescription)")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        logger.debug("Peer connection - did add stream")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        logger.debug("Peer connection - did remove stream")
    }

    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        logger.debug("Peer connection - should negotiate")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        logger.debug("Peer connection - new connection state: \(newState.debugDescription)")

        switch newState {
        case .connected:
            eventSubject.send(.connected)
            if let audioTrack = audioTrack {
                #if os(iOS)
                audioTrack.speakerOn()
                #endif
            }
        case .disconnected:
            eventSubject.send(.disconnected)
        case .closed:
            eventSubject.send(.closed)
        case .failed:
            eventSubject.send(.failed)
        default:
            break
        }
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        logger.debug("Peer connection - new gathering state: \(newState.debugDescription)")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        logger.debug("Peer connection - did generate local candidate")
        let candidate = IceCandidate(
            candidate: candidate.sdp,
            mid: candidate.sdpMid,
            pwd: icePwd
        )
        eventSubject.send(.newIceCandidate(candidate))
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        logger.debug("Peer connection - did remove \(candidates.count) candidate(s)")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        logger.debug("Peer connection - did open data channel")
    }

    func peerConnection(
        _ peerConnection: RTCPeerConnection,
        didAdd rtpReceiver: RTCRtpReceiver,
        streams mediaStreams: [RTCMediaStream]
    ) {
        if let track = rtpReceiver.track as? RTCVideoTrack {
            logger.debug("Peer connection - did set remote video track")
            setRemoteVideoTrack?(track)
        }
    }
}
