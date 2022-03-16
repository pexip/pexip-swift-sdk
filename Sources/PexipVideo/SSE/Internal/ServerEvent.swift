@dynamicMemberLookup
struct ServerEvent: Hashable {
    enum Message: Hashable {
        case chat(ChatMessage)
        case presentationStarted(PresentationDetails)
        case presentationStopped
        case participantSyncBegan
        case participantSyncEnded
        case participantCreated(Participant)
        case participantUpdated(Participant)
        case participantDeleted(ParticipantDeleteDetails)
        case callDisconnected(CallDisconnectDetails)
        case clientDisconnected(ClientDisconnectDetails)
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

    let rawEvent: EventStreamEvent
    let message: Message?

    subscript<T>(dynamicMember keyPath: KeyPath<EventStreamEvent, T>) -> T {
        rawEvent[keyPath: keyPath]
    }
}

// MARK: - Messages

struct CallDisconnectDetails: Codable, Hashable {
    private enum CodingKeys: String, CodingKey {
        case callId = "call_uuid"
        case reason
    }

    let callId: UUID
    let reason: String
}

struct ClientDisconnectDetails: Codable, Hashable {
    let reason: String
}

struct ParticipantDeleteDetails: Codable, Hashable {
    let uuid: UUID
}
