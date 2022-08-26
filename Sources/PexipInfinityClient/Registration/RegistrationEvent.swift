import Foundation

public enum RegistrationEvent: Hashable {
    case incoming(IncomingRegistrationEvent)
    case incomingCancelled(IncomingCancelledRegistrationEvent)

    enum Name: String {
        case incoming = "incoming"
        case incomingCancelled = "incoming_cancelled"
    }
}

// MARK: - Events

public struct IncomingRegistrationEvent: Codable, Hashable {
    private enum CodingKeys: String, CodingKey {
        case conferenceAlias = "conference_alias"
        case remoteDisplayName = "remote_display_name"
        case token
    }

    public let conferenceAlias: String
    public let remoteDisplayName: String
    public let token: String
    public private(set) var receivedAt = Date()

    public init(
        conferenceAlias: String,
        remoteDisplayName: String,
        token: String,
        receivedAt: Date = .init()
    ) {
        self.conferenceAlias = conferenceAlias
        self.remoteDisplayName = remoteDisplayName
        self.token = token
        self.receivedAt = receivedAt
    }
}

public struct IncomingCancelledRegistrationEvent: Codable, Hashable {
    private enum CodingKeys: String, CodingKey {
        case token
    }

    public let token: String
    public private(set) var receivedAt = Date()

    public init(token: String, receivedAt: Date = .init()) {
        self.token = token
        self.receivedAt = receivedAt
    }
}
