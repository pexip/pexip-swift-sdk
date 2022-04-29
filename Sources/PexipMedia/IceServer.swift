public struct IceServer: Hashable {
    public let urls: [String]
    public let username: String?
    public let password: String?

    // MARK: - Init

    public init(
        urls: [String],
        username: String? = nil,
        password: String? = nil
    ) {
        self.urls = urls
        self.username = username
        self.password = password
    }
}
