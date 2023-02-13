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
    public typealias SendMessage = (ChatMessage) async throws -> Bool
    /// The object that acts as the delegate of the chat.
    public weak var delegate: ChatDelegate?
    public var publisher: AnyPublisher<ChatMessage, Never> {
        subject.eraseToAnyPublisher()
    }
    public let senderName: String
    public let senderId: String

    private let subject = PassthroughSubject<ChatMessage, Never>()
    private let _sendMessage: SendMessage

    // MARK: - Init

    public init(
        senderName: String,
        senderId: String,
        sendMessage: @escaping SendMessage
    ) {
        self.senderName = senderName
        self.senderId = senderId
        self._sendMessage = sendMessage
    }

    // MARK: - Public

    public func sendMessage(_ text: String) async throws -> Bool {
        let message = ChatMessage(
            senderName: senderName,
            senderId: senderId,
            payload: text
        )

        guard try await _sendMessage(message) else {
            return false
        }

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
