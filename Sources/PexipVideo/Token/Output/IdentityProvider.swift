/// SSO identity provider
public struct IdentityProvider: Hashable, Decodable {
    /// The name of the identity provider
    public let name: String
    /// The uuid corresponds to the UUID of the configuration on Infinity
    public let uuid: String

    // MARK: - Init

    public init(name: String, uuid: String) {
        self.name = name
        self.uuid = uuid
    }
}
