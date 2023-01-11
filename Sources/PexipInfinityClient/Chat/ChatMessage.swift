import Foundation

/// A chat message that has been sent to the conference.
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
    public let senderId: String

    /// MIME content-type of the message, usually text/plain.
    public let type: String

    /// Message contents.
    public let payload: String

    /// A date when the message was sent or received.
    public private(set) var date = Date()

    @available(*, deprecated, renamed: "date")
    public var receivedAt: Date { date }

    /**
     - Parameters:
        - senderName: Name of the sending participant
        - senderId: UUID of the sending participant
        - type: MIME content-type of the message, usually text/plain
        - payload: Message contents
        - date: A date when the message was sent or received.
     */
    public init(
        senderName: String,
        senderId: String,
        type: String = "text/plain",
        payload: String,
        date: Date = .init()
    ) {
        self.senderName = senderName
        self.senderId = senderId
        self.type = type
        self.payload = payload
        self.date = date
    }
}
