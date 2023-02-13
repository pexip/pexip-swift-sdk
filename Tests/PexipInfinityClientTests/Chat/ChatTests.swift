//
// Copyright 2022-2023 Pexip AS
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import XCTest
import Combine
@testable import PexipInfinityClient

final class ChatTests: XCTestCase {
    private let senderName = "Current User"
    private let senderId = UUID().uuidString
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
        func makeMessage(_ payload: String) -> ChatMessage {
            ChatMessage(
                senderName: senderName,
                senderId: senderId,
                payload: payload
            )
        }

        // 1. Prepare test data
        let messageA = makeMessage("Message A")
        let messageB = makeMessage("Message B")
        let messageC = makeMessage("Message C")
        var publishedMessages = [ChatMessage]()

        // 2. Subscibe to updates
        chat.publisher.sink { message in
            publishedMessages.append(message)
        }.store(in: &cancellables)

        // 3. Send messages with success
        messageSender.isSuccess = true
        let sentMessageA = try await chat.sendMessage(messageA.payload)
        let sentMessageB = try await chat.sendMessage(messageB.payload)

        // 4. Send message with failure
        messageSender.isSuccess = false
        let sentMessageC = try await chat.sendMessage(messageC.payload)

        // 4. Assert
        XCTAssertTrue(sentMessageA)
        XCTAssertTrue(sentMessageB)
        XCTAssertFalse(sentMessageC)
        XCTAssertEqual(publishedMessages.count, 2)
        XCTAssertTrue(publishedMessages.allSatisfy { $0.senderName == senderName })
        XCTAssertTrue(publishedMessages.allSatisfy { $0.senderId == senderId })
        XCTAssertTrue(publishedMessages.allSatisfy { $0.type == "text/plain" })
        XCTAssertEqual(publishedMessages[0].payload, messageA.payload)
        XCTAssertEqual(publishedMessages[1].payload, messageB.payload)
        XCTAssertEqual(delegate.messages, publishedMessages)
        XCTAssertEqual(
            messageSender.messages,
            [messageA.payload, messageB.payload, messageC.payload]
        )
    }

    func testAddMessage() async {
        // 1. Prepare test data
        let messageA = ChatMessage.stub()
        let messageB = ChatMessage.stub()
        var publishedMessages = [ChatMessage]()
        let expectedMessages = [messageA, messageB]

        // 2. Subscibe to updates
        chat.publisher.sink { message in
            publishedMessages.append(message)
        }.store(in: &cancellables)

        // 3. Add messages
        await chat.addMessage(messageA)
        await chat.addMessage(messageB)

        // 4. Assert
        XCTAssertEqual(publishedMessages, expectedMessages)
        XCTAssertEqual(delegate.messages, expectedMessages)
    }
}

// MARK: - Stubs

extension ChatMessage {
    static func stub() -> ChatMessage {
        ChatMessage(
            senderName: "Sender",
            senderId: UUID().uuidString,
            payload: "Message"
        )
    }
}

// MARK: - Mocks

private final class ChatDelegateMock: ChatDelegate {
    private(set) var messages = [ChatMessage]()

    func chat(_ chat: Chat, didReceiveMessage message: ChatMessage) {
        messages.append(message)
    }
}

private final class MessageSender {
    var isSuccess = true
    private(set) var messages = [String]()

    func sendMessage(_ message: ChatMessage) -> Bool {
        messages.append(message.payload)
        return isSuccess
    }
}
