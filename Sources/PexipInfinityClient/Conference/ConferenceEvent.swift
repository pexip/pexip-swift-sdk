import Foundation

public enum ConferenceEvent: Hashable {
    case conferenceUpdate(ConferenceStatus)
    case liveCaptions(LiveCaptions)
    case messageReceived(ChatMessage)
    case presentationStart(PresentationStartMessage)
    case presentationStop
    case participantSyncBegin
    case participantSyncEnd
    case participantCreate(Participant)
    case participantUpdate(Participant)
    case participantDelete(ParticipantDeleteMessage)
    case callDisconnected(CallDisconnectMessage)
    case clientDisconnected(ClientDisconnectMessage)

    enum Name: String {
        case conferenceUpdate = "conference_update"
        case messageReceived = "message_received"
        case presentationStart = "presentation_start"
        case presentationStop = "presentation_stop"
        case participantSyncBegin = "participant_sync_begin"
        case participantSyncEnd = "participant_sync_end"
        case participantCreate = "participant_create"
        case participantUpdate = "participant_update"
        case participantDelete = "participant_delete"
        case callDisconnected = "call_disconnected"
        case clientDisconnected = "disconnect"
        case liveCaptions = "live_captions"
    }
}

// MARK: - Events

public struct ConferenceStatus: Codable, Hashable {
    private enum CodingKeys: String, CodingKey {
        case started
        case locked
        case allMuted = "all_muted"
        case guestsMuted = "guests_muted"
        case presentationAllowed = "presentation_allowed"
        case directMedia = "direct_media"
        case liveCaptionsAvailable = "live_captions_available"
    }

    public let started: Bool
    public let locked: Bool
    public let allMuted: Bool
    public let guestsMuted: Bool
    public let presentationAllowed: Bool
    public let directMedia: Bool
    public let liveCaptionsAvailable: Bool

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        started = try container.decodeIfPresent(Bool.self, forKey: .started) ?? false
        locked = try container.decodeIfPresent(Bool.self, forKey: .locked) ?? false
        allMuted = try container.decodeIfPresent(Bool.self, forKey: .allMuted) ?? false
        guestsMuted = try container.decodeIfPresent(Bool.self, forKey: .guestsMuted) ?? false
        presentationAllowed = try container.decodeIfPresent(
            Bool.self,
            forKey: .presentationAllowed
        ) ?? false
        directMedia = try container.decodeIfPresent(Bool.self, forKey: .directMedia) ?? false
        liveCaptionsAvailable = try container.decodeIfPresent(
            Bool.self,
            forKey: .liveCaptionsAvailable
        ) ?? false
    }
}

public struct PresentationStartMessage: Codable, Hashable {
    private enum CodingKeys: String, CodingKey {
        case presenterName = "presenter_name"
        case presenterUri = "presenter_uri"
    }

    /// Name of the presenter
    public let presenterName: String
    /// URI of the presenter
    public let presenterUri: String
}

public struct CallDisconnectMessage: Codable, Hashable {
    private enum CodingKeys: String, CodingKey {
        case callId = "call_uuid"
        case reason
    }

    public let callId: UUID
    public let reason: String
}

public struct ClientDisconnectMessage: Codable, Hashable {
    public let reason: String
}

public struct ParticipantDeleteMessage: Codable, Hashable {
    private enum CodingKeys: String, CodingKey {
        case id = "uuid"
    }

    public let id: UUID
}

public struct ChatMessage: Codable, Hashable {
    private enum CodingKeys: String, CodingKey {
        case senderName = "origin"
        case senderId = "uuid"
        case type
        case payload
    }

    /// Name of the sending participant.
    public let senderName: String
    /// UUID of the sending participant.
    public let senderId: UUID
    /// MIME content-type of the message, usually text/plain.
    public let type: String
    /// Message contents.
    public let payload: String
    /// Date when the message was received
    public private(set) var receivedAt = Date()

    /**
     - Parameters:
        - senderName: Name of the sending participant
        - senderId: UUID of the sending participant
        - type: MIME content-type of the message, usually text/plain
        - payload: Message contents
        - receivedAt: Date and time when the message was received
     */
    public init(
        senderName: String,
        senderId: UUID,
        type: String = "text/plain",
        payload: String,
        receivedAt: Date = .init()
    ) {
        self.senderName = senderName
        self.senderId = senderId
        self.type = type
        self.payload = payload
        self.receivedAt = receivedAt
    }
}

public struct LiveCaptions: Codable, Hashable {
    private enum CodingKeys: String, CodingKey {
        case data
        case isFinal = "is_final"
        case sentAt = "sent_time"
        case receivedAt = "received_time"
    }

    public let id = UUID()
    public let data: String
    public let isFinal: Bool
    public let sentAt: TimeInterval
    public let receivedAt: TimeInterval

    public init(
        data: String,
        isFinal: Bool,
        sentAt: TimeInterval,
        receivedAt: TimeInterval
    ) {
        self.data = data
        self.isFinal = isFinal
        self.sentAt = sentAt
        self.receivedAt = receivedAt
    }
}
