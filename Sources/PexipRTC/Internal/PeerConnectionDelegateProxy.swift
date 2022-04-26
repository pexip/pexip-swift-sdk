import WebRTC
import PexipUtils

// MARK: - Delegate

protocol PeerConnectionDelegate: AnyObject {
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection)
    func peerConnection(
        _ peerConnection: RTCPeerConnection,
        didChange newState: ConnectionState
    )
    func peerConnection(
        _ peerConnection: RTCPeerConnection,
        didGenerate candidate: RTCIceCandidate
    )
}

// MARK: - Proxy

final class PeerConnectionDelegateProxy: NSObject, RTCPeerConnectionDelegate {
    weak var delegate: PeerConnectionDelegate?
    private let logger: Logger?

    init(logger: Logger?) {
        self.logger = logger
    }

    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        logger?.debug("Peer connection - should negotiate")
        delegate?.peerConnectionShouldNegotiate(peerConnection)
    }

    func peerConnection(
        _ peerConnection: RTCPeerConnection,
        didChange newState: RTCPeerConnectionState
    ) {
        let state = ConnectionState(newState)
        logger?.debug("Peer connection - new connection state: \(state)")
        delegate?.peerConnection(peerConnection, didChange: state)
    }

    func peerConnection(
        _ peerConnection: RTCPeerConnection,
        didGenerate candidate: RTCIceCandidate
    ) {
        logger?.debug("Peer connection - did generate local candidate")
        delegate?.peerConnection(peerConnection, didGenerate: candidate)
    }

    func peerConnection(
        _ peerConnection: RTCPeerConnection,
        didChange stateChanged: RTCSignalingState
    ) {
        let state = SignalingState(stateChanged)
        logger?.debug("Peer connection - new signaling state: \(state)")
    }

    func peerConnection(
        _ peerConnection: RTCPeerConnection,
        didAdd stream: RTCMediaStream
    ) {
        logger?.debug("Peer connection - did add stream")
    }

    func peerConnection(
        _ peerConnection: RTCPeerConnection,
        didRemove stream: RTCMediaStream
    ) {
        logger?.debug("Peer connection - did remove stream")
    }

    func peerConnection(
        _ peerConnection: RTCPeerConnection,
        didChange newState: RTCIceConnectionState
    ) {
        let state = IceConnectionState(newState)
        logger?.debug("Peer connection - new connection state: \(state)")
    }

    func peerConnection(
        _ peerConnection: RTCPeerConnection,
        didChange newState: RTCIceGatheringState
    ) {
        let state = IceGatheringState(newState)
        logger?.debug("Peer connection - new gathering state: \(state)")
    }

    func peerConnection(
        _ peerConnection: RTCPeerConnection,
        didRemove candidates: [RTCIceCandidate]
    ) {
        let count = candidates.count
        logger?.debug("Peer connection - did remove \(count) candidate(s)")
    }

    func peerConnection(
        _ peerConnection: RTCPeerConnection,
        didOpen dataChannel: RTCDataChannel
    ) {
        logger?.debug("Peer connection - did open data channel")
    }
}
