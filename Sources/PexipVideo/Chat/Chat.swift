import Combine

// MARK: - Delegate

public protocol ChatDelegate: AnyObject {
    func chat(_ chat: Chat, didReceiveMessage message: ChatMessage)
    func chatDidClearMessages(_ chat: Chat)
}

// MARK: - Chat

public final class Chat: ObservableObject {
    public typealias SendMessage = (String) async throws -> Bool
    /// The object that acts as the delegate of the chat.
    public weak var delegate: ChatDelegate?
    @Published public private(set) var messages = [ChatMessage]()
    public let senderName: String
    public let senderId: UUID

    private let _sendMessage: SendMessage

    // MARK: - Init

    public init(
        senderName: String,
        senderId: UUID,
        messages: [ChatMessage] = [],
        sendMessage: @escaping SendMessage
    ) {
        self.senderName = senderName
        self.senderId = senderId
        self.messages = messages
        self._sendMessage = sendMessage
    }

    // MARK: - Public

    public func sendMessage(_ text: String) async throws -> Bool {
        guard try await _sendMessage(text) else {
            return false
        }

        let message = ChatMessage(
            senderName: senderName,
            senderId: senderId,
            payload: text
        )
        await addMessage(message)

        return true
    }

    // MARK: - Internal

    func addMessage(_ message: ChatMessage) async {
        await MainActor.run {
            messages.append(message)
            delegate?.chat(self, didReceiveMessage: message)
        }
    }

    func clear() async {
        await MainActor.run {
            messages.removeAll()
            delegate?.chatDidClearMessages(self)
        }
    }
}
