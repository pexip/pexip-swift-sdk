import WebRTC

enum IceConnectionState: String, CustomStringConvertible, CaseIterable {
    case new
    case checking
    case connected
    case completed
    case failed
    case disconnected
    case closed
    case count
    case unknown

    init(_ value: RTCIceConnectionState) {
        switch value {
        case .new:
            self = .new
        case .checking:
            self = .checking
        case .connected:
            self = .connected
        case .completed:
            self = .completed
        case .failed:
            self = .failed
        case .disconnected:
            self = .disconnected
        case .closed:
            self = .closed
        case .count:
            self = .count
        @unknown default:
            self = .unknown
        }
    }

    var description: String {
        rawValue.capitalized
    }
}
