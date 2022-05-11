public enum MediaConnectionState: String, CustomStringConvertible, CaseIterable {
    case new
    case connecting
    case connected
    case disconnected
    case failed
    case closed
    case unknown

    public var description: String {
        rawValue.capitalized
    }
}
