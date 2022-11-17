public struct IceServer: Hashable {
    public enum Kind {
        case turn
        case stun
    }

    public let kind: Kind
    public let urls: [String]
    public let username: String?
    public let password: String?

    // MARK: - Init

    public init(
        kind: Kind,
        urls: [String],
        username: String? = nil,
        password: String? = nil
    ) {
        self.kind = kind
        self.urls = urls
        self.username = username
        self.password = password
    }

    public init(
        kind: Kind,
        url: String,
        username: String? = nil,
        password: String? = nil
    ) {
        self.init(kind: kind, urls: [url], username: username, password: password)
    }
}
