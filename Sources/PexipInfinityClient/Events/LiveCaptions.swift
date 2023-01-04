import Foundation

/// Live caption event details.
public struct LiveCaptions: Codable, Hashable {
    private enum CodingKeys: String, CodingKey {
        case data
        case isFinal = "is_final"
        case sentAt = "sent_time"
    }

    public let data: String
    public let isFinal: Bool
    public let sentAt: TimeInterval?

    public init(
        data: String,
        isFinal: Bool,
        sentAt: TimeInterval?
    ) {
        self.data = data
        self.isFinal = isFinal
        self.sentAt = sentAt
    }
}
