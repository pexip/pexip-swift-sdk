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
    public let receivedAt = Date()

    /**
     - Parameters:
        - senderName: Name of the sending participant
        - senderId: UUID of the sending participant
        - type: MIME content-type of the message, usually text/plain
        - payload: Message contents
     */
    public init(
        senderName: String,
        senderId: UUID,
        type: String = "text/plain",
        payload: String
    ) {
        self.senderName = senderName
        self.senderId = senderId
        self.type = type
        self.payload = payload
    }
}
