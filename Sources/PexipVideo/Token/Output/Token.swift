import Foundation

public struct Token: Decodable, Hashable {
    public enum Role: String, Decodable, Hashable {
        case host = "HOST"
        case guest = "GUEST"
    }

    public struct Stun: Decodable, Hashable {
        let url: String
    }

    private enum CodingKeys: String, CodingKey {
        case value = "token"
        case expiresString = "expires"
        case participantId = "participant_uuid"
        case role
        case displayName = "display_name"
        case serviceType = "service_type"
        case conferenceName = "conference_name"
        case stun
    }

    /// The authentication token for future requests.
    public private(set) var value: String
    /// Date when the token was requested
    public private(set) var updatedAt = Date()
    /// The uuid associated with this newly created participant.
    /// It is used to identify this participant in the participant list.
    public let participantId: UUID
    /// Whether the participant is connecting as a "HOST" or a "GUEST".
    public let role: Role
    /// The name by which this participant should be known
    public let displayName: String
    /// VMR, gateway or Test Call Service
    public let serviceType: String
    /// The name of the conference
    public let conferenceName: String
    // STUN server configuration from the Pexip Conferencing Node
    public let stun: [Stun]
    /// Validity lifetime in seconds.
    public var expires: TimeInterval {
        TimeInterval(expiresString) ?? 0
    }

    var expiresAt: Date {
        updatedAt.addingTimeInterval(expires)
    }

    var refreshDate: Date {
        let refreshInterval = expires / 2
        return updatedAt.addingTimeInterval(refreshInterval)
    }

    func isExpired(currentDate: Date = .init()) -> Bool {
        currentDate >= expiresAt
    }

    var iceServers: [String] {
        stun.map(\.url)
    }

    private var expiresString: String

    // MARK: - Init

    public init(
        value: String,
        updatedAt: Date = Date(),
        participantId: UUID,
        role: Token.Role,
        displayName: String,
        serviceType: String,
        conferenceName: String,
        stun: [Token.Stun],
        expiresString: String
    ) {
        self.value = value
        self.updatedAt = updatedAt
        self.participantId = participantId
        self.role = role
        self.displayName = displayName
        self.serviceType = serviceType
        self.conferenceName = conferenceName
        self.stun = stun
        self.expiresString = expiresString
    }

    // MARK: - Update

    mutating func update(value: String, expires: String, updatedAt: Date = .init()) {
        self.value = value
        self.expiresString = expires
        self.updatedAt = updatedAt
    }
}
