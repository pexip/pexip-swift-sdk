import Foundation
import WebRTC

protocol WebRTCClientDelegate: AnyObject {
    func webRTCClient(_ client: WebRTCClient, didDiscoverLocalCandidate candidate: RTCIceCandidate)
    func webRTCClient(_ client: WebRTCClient, didChangeConnectionState state: RTCIceConnectionState)
}

final class WebRTCClient: NSObject, RTCPeerConnectionDelegate {
    weak var delegate: WebRTCClientDelegate?

    private let factory: RTCPeerConnectionFactory
    private let peerConnection: RTCPeerConnection
    private let camera: RTCCameraComponent
    private let audio: RTCAudioComponent
    private let remoteVideo = RTCRemoteVideoComponent()
    private let logger: CategoryLogger

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

    func createOffer() async throws -> RTCSessionDescription {
        let constrains = RTCMediaConstraints.constraints(withEnabledVideo: true, audio: true)
        let sdp = try await peerConnection.offer(for: constrains)
        try await peerConnection.setLocalDescription(sdp)
        return sdp
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
        delegate?.webRTCClient(self, didChangeConnectionState: newState)
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        logger.debug("Peer connection - new gathering state: \(newState)")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        logger.debug("Peer connection - did generate local candidate")
        delegate?.webRTCClient(self, didDiscoverLocalCandidate: candidate)
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
