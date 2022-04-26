import WebRTC

public enum ConnectionState: String, CustomStringConvertible, CaseIterable {
    case new
    case connecting
    case connected
    case disconnected
    case failed
    case closed
    case unknown

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

    public var description: String {
        rawValue.capitalized
    }
}
