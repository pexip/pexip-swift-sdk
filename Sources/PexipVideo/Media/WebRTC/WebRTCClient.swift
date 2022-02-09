import Foundation
import WebRTC

final class WebRTCClient: NSObject, RTCPeerConnectionDelegate {
    let camera: RTCCameraComponent
    let audio: RTCAudioComponent
    let remoteVideo = RTCRemoteVideoComponent()

    private let factory: RTCPeerConnectionFactory
    private let peerConnection: RTCPeerConnection
    private let logger: CategoryLogger
    private var localOfferContinuation: CheckedContinuation<String, Error>?

    // MARK: - Init

    @available(*, unavailable)
    override init() {
        fatalError("WebRTCClient:init is unavailable")
    }

    required init(
        iceServers: [String],
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

        let streamId = UUID().uuidString

        self.factory = factory
        self.peerConnection = peerConnection
        self.camera = RTCCameraComponent(
            factory: factory,
            trackManager: peerConnection,
            streamId: streamId
        )
        self.audio = RTCAudioComponent(
            factory: factory,
            trackManager: peerConnection,
            streamId: streamId
        )
        self.logger = logger[.media]
        super.init()
        self.peerConnection.delegate = self
    }

    // MARK: - Signaling

    func createOffer() async throws -> String {
        let constrains = RTCMediaConstraints.constraints(withEnabledVideo: true, audio: true)
        let sdp = try await peerConnection.offer(for: constrains)
        try await peerConnection.setLocalDescription(sdp)

        return try await withCheckedThrowingContinuation { continuation in
            self.localOfferContinuation = continuation
        }
    }

    func setRemoteSessionDescription(_ string: String) async throws {
        let string = SDPMangler(sdp: string).sdp(withBandwidth: 768, isPresentation: false)
        let sdp = RTCSessionDescription(type: .answer, sdp: string)
        try await peerConnection.setRemoteDescription(sdp)
    }

    func addRemoteCandidate(_ candidate: RTCIceCandidate) async throws {
        try await peerConnection.add(candidate)
    }

    // MARK: - RTCPeerConnectionDelegate

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        logger.debug("Peer connection - new signaling state: \(stateChanged)")
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
        logger.debug("Peer connection - new connection state: \(newState)")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        logger.debug("Peer connection - new gathering state: \(newState)")
        if newState == .complete {
            if let localDescription = peerConnection.localDescription {
                let string = SDPMangler(sdp: localDescription.sdp)
                    .sdp(withBandwidth: 768, isPresentation: false)
                localOfferContinuation?.resume(returning: string)
            } else {
                localOfferContinuation?.resume(throwing: MediaError.iceGatheringFailed)
            }
        }
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        logger.debug("Peer connection - did generate local candidate")
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
            remoteVideo.setTrack(track)
        }
    }
}
