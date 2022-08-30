import Foundation

public struct ConferenceToken: InfinityToken, Codable, Hashable {
    public enum Role: String, Codable, Hashable {
        case host = "HOST"
        case guest = "GUEST"
    }

    public struct Stun: Codable, Hashable {
        public let url: String
    }

    public struct Turn: Codable, Hashable {
        public let urls: [String]
        public let username: String
        public let credential: String
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
        case turn
        case chatEnabled = "chat_enabled"
        case analyticsEnabled = "analytics_enabled"
        case version
    }

    /// A textual representation of this instance, suitable for debugging.
    public let debugDescription = "Conference token"

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
    public let stun: [Stun]?

    // TURN server configuration from the Pexip Conferencing Node
    public let turn: [Turn]?

    /// true = chat is enabled; false = chat is not enabled
    public let chatEnabled: Bool

    /// Whether the Automatically send deployment and usage statistics
    /// to Pexip global setting has been enabled on the Pexip installation.
    public let analyticsEnabled: Bool

    /// The version of the Pexip server being communicated with.
    public let version: Version

    /// Validity lifetime in seconds.
    public var expires: TimeInterval {
        TimeInterval(expiresString) ?? 0
    }

    private(set) var expiresString: String

    // MARK: - Init

    public init(
        value: String,
        updatedAt: Date = Date(),
        participantId: UUID,
        role: ConferenceToken.Role,
        displayName: String,
        serviceType: String,
        conferenceName: String,
        stun: [ConferenceToken.Stun]?,
        turn: [ConferenceToken.Turn]?,
        chatEnabled: Bool,
        analyticsEnabled: Bool,
        expiresString: String,
        version: Version
    ) {
        self.value = value
        self.updatedAt = updatedAt
        self.participantId = participantId
        self.role = role
        self.displayName = displayName
        self.serviceType = serviceType
        self.conferenceName = conferenceName
        self.stun = stun
        self.turn = turn
        self.chatEnabled = chatEnabled
        self.analyticsEnabled = analyticsEnabled
        self.expiresString = expiresString
        self.version = version
    }

    // MARK: - Update

    public func updating(
        value: String,
        expires: String,
        updatedAt: Date = .init()
    ) -> ConferenceToken {
        var token = self
        token.value = value
        token.expiresString = expires
        token.updatedAt = updatedAt
        return token
    }
}
