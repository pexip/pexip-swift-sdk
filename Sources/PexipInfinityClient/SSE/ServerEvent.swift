import Foundation

@dynamicMemberLookup
public struct ServerEvent: Hashable {
    public enum Message: Hashable {
        case chat(ChatMessage)
        case presentationStarted(PresentationStartMessage)
        case presentationStopped
        case participantSyncBegan
        case participantSyncEnded
        case participantCreated(Participant)
        case participantUpdated(Participant)
        case participantDeleted(ParticipantDeleteMessage)
        case callDisconnected(CallDisconnectMessage)
        case clientDisconnected(ClientDisconnectMessage)
    }

    enum Name: String {
        case chat = "message_received"
        case presentationStarted = "presentation_start"
        case presentationStopped = "presentation_stop"
        case participantSyncBegan = "participant_sync_begin"
        case participantSyncEnded = "participant_sync_end"
        case participantCreated = "participant_create"
        case participantUpdated = "participant_update"
        case participantDeleted = "participant_delete"
        case callDisconnected = "call_disconnected"
        case clientDisconnected = "disconnect"
    }

    public let rawEvent: EventSourceEvent
    public let message: Message?

    public subscript<T>(dynamicMember keyPath: KeyPath<EventSourceEvent, T>) -> T {
        rawEvent[keyPath: keyPath]
    }
}

// MARK: - Messages

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
