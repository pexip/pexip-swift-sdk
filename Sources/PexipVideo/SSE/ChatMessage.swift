public struct ChatMessage: Codable, Hashable {
    /// Name of the sending participant.
    public let origin: String
    /// UUID of the sending participant.
    public let uuid: UUID
    /// MIME content-type of the message, usually text/plain.
    public let type: String
    /// Message contents.
    public let payload: String
}
