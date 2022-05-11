import WebRTC

enum IceGatheringState: String, CustomStringConvertible, CaseIterable {
    case new
    case gathering
    case complete
    case unknown

    init(_ value: RTCIceGatheringState) {
        switch value {
        case .new:
            self = .new
        case .gathering:
            self = .gathering
        case .complete:
            self = .complete
        @unknown default:
            self = .unknown
        }
    }

    var description: String {
        rawValue.capitalized
    }
}
