import WebRTC

enum DataChannelState: String, CustomStringConvertible, CaseIterable {
    case connecting
    case open
    case closing
    case closed
    case unknown

    init(_ value: RTCDataChannelState) {
        switch value {
        case .connecting:
            self = .connecting
        case .open:
            self = .open
        case .closing:
            self = .closing
        case .closed:
            self = .closed
        @unknown default:
            self = .unknown
        }
    }

    var description: String {
        rawValue.capitalized
    }
}
