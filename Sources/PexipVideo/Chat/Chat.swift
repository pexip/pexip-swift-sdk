import Combine

// MARK: - Protocols

public protocol ChatDelegate: AnyObject {
    func chat(
        _ chat: Chat,
        didReceiveMessage message: ChatMessage
    )
}

// MARK: - Chat

public final class Chat {
    public typealias SendMessage = (String) async throws -> Bool

    public weak var delegate: ChatDelegate?
    public var publisher: AnyPublisher<ChatMessage, Never> {
        subject.eraseToAnyPublisher()
    }
    public private(set) var messages = [ChatMessage]()

    private let subject = PassthroughSubject<ChatMessage, Never>()
    private let senderName: String
    private let senderId: UUID
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
        if try await _sendMessage(text) {
            let message = ChatMessage(
                senderName: senderName,
                senderId: senderId,
                payload: text
            )
            appendMessage(message)
            return true
        } else {
            return false
        }
    }

    // MARK: - Internal

    func appendMessage(_ message: ChatMessage) {
        Task { @MainActor in
            self.messages.append(message)
            delegate?.chat(self, didReceiveMessage: message)
            subject.send(message)
        }
    }

    func clear() {
        messages.removeAll()
    }
}
