import Foundation

enum DataMessage: Codable {
    case text(ChatMessage)

    private enum CodingKeys: String, CodingKey {
        case type
        case body
    }

    private enum MessageType: String, Codable {
        case text = "message"
    }

    // MARK: - Codable

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(MessageType.self, forKey: .type)

        switch type {
        case .text:
            self = .text(try container.decode(ChatMessage.self, forKey: .body))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .text(let chatMessage):
            try container.encode(MessageType.text, forKey: .type)
            try container.encode(chatMessage, forKey: .body)
        }
    }
}
