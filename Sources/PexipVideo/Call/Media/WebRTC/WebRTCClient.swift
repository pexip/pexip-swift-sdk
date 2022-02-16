import Foundation
import WebRTC
import Combine

final class WebRTCClient: NSObject, CallConnection, RTCPeerConnectionDelegate {
    let supportsAudio: Bool
    let supportsVideo: Bool
    var iceCandidate: AnyPublisher<IceCandidate, Never> { iceCandidateSubject.eraseToAnyPublisher() }

    private(set) var camera: CameraComponent?
    private(set) var audio: AudioComponent?
    private(set) var remoteVideo: VideoComponent?

    private let factory: RTCPeerConnectionFactory
    private let peerConnection: RTCPeerConnection
    private let logger: CategoryLogger
    private let qualityProfile: QualityProfile
    private var setRemoteVideoTrack: ((RTCVideoTrack) -> Void)?
    private let localStreamId = UUID().uuidString
    private var icePwd: String?
    private let iceCandidateSubject = PassthroughSubject<IceCandidate, Never>()

    // MARK: - Init

    @available(*, unavailable)
    override init() {
        fatalError("WebRTCClient:init is unavailable")
    }

    required init(
        iceServers: [String],
        qualityProfile: QualityProfile,
        supportsAudio: Bool = true,
        supportsVideo: Bool = true,
        factory: RTCPeerConnectionFactory = .default,
        logger: LoggerProtocol
    ) {
        guard let peerConnection = factory.peerConnection(
            with: .configuration(withIceServers: iceServers),
            constraints: .constraints(withEnabledVideo: true, audio: true),
            delegate: nil
        ) else {
            fatalError("Could not create new RTCPeerConnection")
        }

        self.supportsAudio = supportsAudio
        self.supportsVideo = supportsVideo
        self.factory = factory
        self.peerConnection = peerConnection
        self.logger = logger[.media]
        self.qualityProfile = qualityProfile

        super.init()

        self.peerConnection.delegate = self
        setupMedia()
    }

    // MARK: - Setup

    private func setupMedia() {
        if supportsVideo {
            self.camera = RTCCameraComponent(
                factory: factory,
                trackManager: peerConnection,
                streamId: localStreamId
            )
            let remoteVideo = RTCVideoComponent(track: nil)
            self.setRemoteVideoTrack = {
                remoteVideo.setTrack($0)
            }
            self.remoteVideo = remoteVideo
        }

        if supportsAudio {
            self.audio = RTCAudioComponent(
                factory: factory,
                trackManager: peerConnection,
                streamId: localStreamId
            )
        }
    }

    // MARK: - Signaling

    func createOffer() async throws -> String {
        let constrains = RTCMediaConstraints.constraints(withEnabledVideo: true, audio: true)
        let offer = try await peerConnection.offer(for: constrains)
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
        iceCandidateSubject.send(candidate)
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
