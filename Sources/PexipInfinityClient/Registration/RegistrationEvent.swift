import Foundation

public enum RegistrationEvent: Hashable {
    case incoming(IncomingRegistrationEvent)
    case incomingCancelled(IncomingCancelledRegistrationEvent)
    case failure(FailureRegistrationEvent)

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
    public let receivedAt = Date()

    public init(conferenceAlias: String, remoteDisplayName: String, token: String) {
        self.conferenceAlias = conferenceAlias
        self.remoteDisplayName = remoteDisplayName
        self.token = token
    }
}

public struct IncomingCancelledRegistrationEvent: Codable, Hashable {
    private enum CodingKeys: String, CodingKey {
        case token
    }

    public let receivedAt = Date()
    public let token: String

    public init(token: String) {
        self.token = token
    }
}

public struct FailureRegistrationEvent: Codable, Hashable {
    public private(set) var receivedAt = Date()
}
