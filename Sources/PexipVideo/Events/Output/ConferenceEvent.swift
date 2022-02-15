enum ConferenceEvent {
    case chatMessage(ChatMessage)
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
