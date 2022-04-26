/// SSO identity provider
public struct IdentityProvider: Hashable, Decodable {
    private enum CodingKeys: String, CodingKey {
        case name
        case id = "uuid"
    }

    /// The name of the identity provider
    public let name: String
    /// The uuid corresponds to the UUID of the configuration on Infinity
    public let id: String

    // MARK: - Init

    public init(name: String, id: String) {
        self.name = name
        self.id = id
    }
}
