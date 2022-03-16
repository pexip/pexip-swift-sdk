import XCTest
import Combine
@testable import PexipVideo

final class ChatTests: XCTestCase {
    private let senderName = "Current User"
    private let senderId = UUID()
    private var chat: Chat!
    private var delegate: ChatDelegateMock!
    private var messageSender: MessageSender!
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        delegate = ChatDelegateMock()
        messageSender = MessageSender()
        chat = Chat(
            senderName: senderName,
            senderId: senderId,
            messages: [],
            sendMessage: { [weak self] message in
                return self?.messageSender.sendMessage(message) == true
            })
        chat.delegate = delegate
    }

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    // MARK: - Tests

    func testInit() {
        XCTAssertEqual(chat.senderName, senderName)
        XCTAssertEqual(chat.senderId, senderId)
    }

    func testSendMessage() async throws {
        // 1. Prepare test data
        let messageA = "Message A"
        let messageB = "Message B"
        let messageC = "Message C"
        var publishCount = 0
        var publishedMessages = [[ChatMessage]]()

        // 2. Subscibe to updates
        chat.$messages.sink { messages in
            publishedMessages.append(messages)
            publishCount += 1
        }.store(in: &cancellables)

        // 3. Send messages with success
        messageSender.isSuccess = true
        let sentMessageA = try await chat.sendMessage(messageA)
        let sentMessageB = try await chat.sendMessage(messageB)

        // 4. Send message with failure
        messageSender.isSuccess = false
        let sentMessageC = try await chat.sendMessage(messageC)

        // 4. Assert
        XCTAssertTrue(sentMessageA)
        XCTAssertTrue(sentMessageB)
        XCTAssertFalse(sentMessageC)
        XCTAssertEqual(
            publishedMessages,
            [[], [chat.messages[0]], [chat.messages[0], chat.messages[1]]]
        )
        XCTAssertEqual(publishCount, 3)
        XCTAssertEqual(chat.messages.count, 2)
        XCTAssertTrue(chat.messages.allSatisfy { $0.senderName == senderName })
        XCTAssertTrue(chat.messages.allSatisfy { $0.senderId == senderId })
        XCTAssertTrue(chat.messages.allSatisfy { $0.type == "text/plain" })
        XCTAssertEqual(chat.messages[0].payload, messageA)
        XCTAssertEqual(chat.messages[1].payload, messageB)
        XCTAssertEqual(delegate.messages, chat.messages)
        XCTAssertEqual(messageSender.messages, [messageA, messageB, messageC])
    }

    func testAddMessage() async {
        // 1. Prepare test data
        let messageA = ChatMessage.stub()
        let messageB = ChatMessage.stub()
        var publishCount = 0
        var publishedMessages = [[ChatMessage]]()
        let expectedMessages = [messageA, messageB]

        // 2. Subscibe to updates
        chat.$messages.sink { messages in
            publishedMessages.append(messages)
            publishCount += 1
        }.store(in: &cancellables)

        // 3. Add messages
        await chat.addMessage(messageA)
        await chat.addMessage(messageB)

        // 4. Assert
        XCTAssertEqual(
            publishedMessages,
            [[], [messageA], [messageA, messageB]]
        )
        XCTAssertEqual(publishCount, 3)
        XCTAssertEqual(chat.messages, expectedMessages)
        XCTAssertEqual(delegate.messages, expectedMessages)
    }

    func testClear() async {
        // 1. Prepare test data
        let messageA = ChatMessage.stub()
        let messageB = ChatMessage.stub()
        var publishCount = 0
        var publishedMessages = [[ChatMessage]]()

        // 2. Subscibe to updates
        chat.$messages.sink { messages in
            publishedMessages.append(messages)
            publishCount += 1
        }.store(in: &cancellables)

        // 3. Add messages
        await chat.addMessage(messageA)
        await chat.addMessage(messageB)
        await chat.clear()

        // 4. Assert
        XCTAssertEqual(
            publishedMessages,
            [[], [messageA], [messageA, messageB], []]
        )
        XCTAssertEqual(publishCount, 4)
        XCTAssertTrue(chat.messages.isEmpty)
        XCTAssertTrue(delegate.messages.isEmpty)
    }
}

// MARK: - Stubs

extension ChatMessage {
    static func stub() -> ChatMessage {
        ChatMessage(senderName: "Sender", senderId: UUID(), payload: "Message")
    }
}

// MARK: - Mocks

private final class ChatDelegateMock: ChatDelegate {
    private(set) var messages = [ChatMessage]()

    func chat(_ chat: Chat, didReceiveMessage message: ChatMessage) {
        messages.append(message)
    }

    func chatDidClearMessages(_ chat: Chat) {
        messages = []
    }
}

private final class MessageSender {
    var isSuccess = true
    private(set) var messages = [String]()

    func sendMessage(_ message: String) -> Bool {
        messages.append(message)
        return isSuccess
    }
}
