import Foundation
import Combine

// MARK: - Delegate

/// The object that acts as the delegate of the chat object.
public protocol ChatDelegate: AnyObject {
    func chat(_ chat: Chat, didReceiveMessage message: ChatMessage)
}

// MARK: - Chat

/// The object responsible for sending and receiving text messages in the conference
public final class Chat {
    public typealias SendMessage = (String) async throws -> Bool
    /// The object that acts as the delegate of the chat.
    public weak var delegate: ChatDelegate?
    public var publisher: AnyPublisher<ChatMessage, Never> {
        subject.eraseToAnyPublisher()
    }
    public let senderName: String
    public let senderId: UUID

    private let subject = PassthroughSubject<ChatMessage, Never>()
    private let _sendMessage: SendMessage

    // MARK: - Init

    public init(
        senderName: String,
        senderId: UUID,
        sendMessage: @escaping SendMessage
    ) {
        self.senderName = senderName
        self.senderId = senderId
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
            subject.send(message)
            delegate?.chat(self, didReceiveMessage: message)
        }
    }
}
