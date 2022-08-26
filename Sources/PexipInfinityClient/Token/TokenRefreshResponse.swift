/// The new token for future requests.
public struct TokenRefreshResponse: Decodable, Hashable {
    /// The new token for future requests.
    public let token: String
    /// Validity lifetime in seconds.
    public let expires: String

    // MARK: - Init

    public init(token: String, expires: String) {
        self.token = token
        self.expires = expires
    }
}
