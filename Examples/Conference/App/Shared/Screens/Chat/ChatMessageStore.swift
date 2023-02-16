//
// Copyright 2022 Pexip AS
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
import PexipInfinityClient
import Combine

final class ChatMessageStore: ObservableObject {
    @Published private(set) var messages = [Chat.Message]()
    private let chat: Chat
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init(chat: Chat, roster: Roster, messages: [Chat.Message] = []) {
        self.chat = chat

        chat.publisher.sink(receiveValue: { [weak self] message in
            self?.messages.append(.init(
                title: message.senderName,
                text: message.payload,
                date: message.date
            ))
        }).store(in: &cancellables)

        roster.eventPublisher.sink(receiveValue: { [weak self] event in
            guard let self = self else { return }

            let senderName = "Chatbot"

            switch event {
            case .added(let participant):
                self.messages.append(.init(
                    title: senderName,
                    text: "\(participant.displayName) joined"
                ))
            case .deleted(let participant):
                self.messages.append(.init(
                    title: senderName,
                    text: "\(participant.displayName) left"
                ))
            case .updated, .reloaded:
                break
            }
        }).store(in: &cancellables)
    }

    // MARK: - Internal

    func addMessage(_ text: String) async throws -> Bool {
        guard !text.isEmpty else {
            return false
        }

        return try await chat.sendMessage(text)
    }
}

// MARK: - Message

extension Chat {
    struct Message: Hashable {
        static let dateFormatter: DateFormatter = {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "hh:mm"
            return dateFormatter
        }()

        let title: String
        let text: String
        var date = Date()

        var timeString: String {
            Self.dateFormatter.string(from: date)
        }
    }
}
