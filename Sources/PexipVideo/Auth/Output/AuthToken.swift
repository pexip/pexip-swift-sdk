import Foundation

struct AuthToken: Hashable {
    private enum CodingKeys: String, CodingKey {
        case token
        case expires
        case role
    }

    enum Role: String, Decodable, Hashable {
        case host = "HOST"
        case guest = "GUEST"
    }

    /// The authentication token for future requests.
    let value: String
    /// Validity lifetime in seconds.
    let expires: TimeInterval
    /// Whether the participant is connecting as a "HOST" or a "GUEST".
    let role: Role
    /// Date when the token was requested
    private(set) var createdAt = Date()

    init(value: String, expires: String, role: Role, createdAt: Date = .init()) {
        self.value = value
        self.expires = TimeInterval(expires) ?? 0
        self.role = role
        self.createdAt = createdAt
    }

    var expiresAt: Date {
        createdAt.addingTimeInterval(expires)
    }

    var refreshDate: Date {
        createdAt.addingTimeInterval(expires / 2)
    }

    func isExpired(currentDate: Date = .init()) -> Bool {
        currentDate >= expiresAt
    }
}

extension AuthToken: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let value = try container.decode(String.self, forKey: .token)
        let expires = try container.decode(String.self, forKey: .expires)
        let role = try container.decode(Role.self, forKey: .role)
        self.init(value: value, expires: expires, role: role)
    }
}
