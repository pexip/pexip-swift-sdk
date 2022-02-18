enum ServerSentEvent {
    case chatMessage(ChatMessage)
    case callDisconnected(CallDisconnected)
    case disconnect(Disconnect)
}

// MARK: - Events

public struct ChatMessage: Decodable {
    /// Name of the sending participant.
    let origin: String
    /// UUID of the sending participant.
    let uuid: UUID
    /// MIME content-type of the message, usually text/plain.
    let type: String
    /// Message contents.
    let payload: String
}

struct CallDisconnected: Decodable {
    private enum CodingKeys: String, CodingKey {
        case callId = "call_uuid"
        case reason
    }

    let callId: UUID
    let reason: String
}

struct Disconnect: Decodable {
    let reason: String
}
