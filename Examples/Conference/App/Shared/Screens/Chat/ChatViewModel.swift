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
import Combine
import PexipInfinityClient

final class ChatViewModel: ObservableObject {
    @Published private(set) var messages: [Chat.Message]
    @Published var text = ""
    @Published var showingErrorBadge = false
    private let store: ChatMessageStore
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init(store: ChatMessageStore) {
        self.store = store
        self.messages = store.messages
        addEventListeners()
    }

    // MARK: - Actions

    func send() {
        showingErrorBadge = false

        Task { @MainActor in
            do {
                showingErrorBadge = try await !store.addMessage(text)
            } catch {
                showingErrorBadge = true
                debugPrint("Cannot send message, error: \(error)")
            }

            if !showingErrorBadge {
                text = ""
            }
        }
    }

    // MARK: - Private

    private func addEventListeners() {
        // Hide error badge when text changes
        text.publisher.sink { [weak self] _ in
            self?.showingErrorBadge = false
        }.store(in: &cancellables)

        store.$messages.sink { [weak self] messages in
            self?.messages = messages
        }.store(in: &cancellables)
    }
}
