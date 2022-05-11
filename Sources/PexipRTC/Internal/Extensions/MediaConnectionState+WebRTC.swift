import WebRTC
import PexipMedia

extension MediaConnectionState {
    init(_ value: RTCPeerConnectionState) {
        switch value {
        case .new:
            self = .new
        case .connecting:
            self = .connecting
        case .connected:
            self = .connected
        case .disconnected:
            self = .disconnected
        case .failed:
            self = .failed
        case .closed:
            self = .closed
        @unknown default:
            self = .unknown
        }
    }
}
