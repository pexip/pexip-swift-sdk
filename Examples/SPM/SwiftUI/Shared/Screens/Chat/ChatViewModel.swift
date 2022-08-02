import Foundation
import Combine
import PexipConference

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
