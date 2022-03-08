@dynamicMemberLookup
struct ServerEvent: Hashable {
    enum Message: Hashable {
        case chat(ChatMessage)
        case callDisconnected(CallDisconnectDetails)
        case participantDisconnected(ParticipantDisconnectDetails)
        case presentationStarted(PresentationDetails)
        case presentationStopped
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

struct ParticipantDisconnectDetails: Codable, Hashable {
    let reason: String
}
