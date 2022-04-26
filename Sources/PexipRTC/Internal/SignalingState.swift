import WebRTC

enum SignalingState: String, CustomStringConvertible, CaseIterable {
    case stable
    case haveLocalOffer
    case haveLocalPrAnswer
    case haveRemoteOffer
    case haveRemotePrAnswer
    case closed
    case unknown

    init(_ value: RTCSignalingState) {
        switch value {
        case .stable:
            self = .stable
        case .haveLocalOffer:
            self = .haveLocalOffer
        case .haveLocalPrAnswer:
            self = .haveLocalPrAnswer
        case .haveRemoteOffer:
            self = .haveRemoteOffer
        case .haveRemotePrAnswer:
            self = .haveRemotePrAnswer
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
