public struct PresentationDetails: Codable, Hashable {
    private enum CodingKeys: String, CodingKey {
        case presenterName = "presenter_name"
        case presenterUri = "presenter_uri"
    }

    /// Name of the presenter
    public let presenterName: String
    /// URI of the presenter
    public let presenterUri: String
}
