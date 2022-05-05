import Foundation
import Combine
import PexipConference

final class ChatViewModel: ObservableObject {
    @Published private(set) var messages: [Message]
    @Published var text = ""
    @Published var showingErrorBadge = false
    var canSend: Bool {
        !text.isEmpty
    }
    private let chat: Chat
    private let roster: Roster
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init(chat: Chat, roster: Roster, messages: [Message] = []) {
        self.chat = chat
        self.roster = roster
        self.messages = messages
        addEventListeners()
    }

    // MARK: - Actions

    func send() {
        guard canSend else {
            return
        }

        showingErrorBadge = false

        Task { @MainActor in
            do {
                showingErrorBadge = try await !chat.sendMessage(text)
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

        chat.publisher.sink(receiveValue: { [weak self] message in
            self?.messages.append(Message(
                title: message.senderName,
                text: message.payload,
                date: message.receivedAt
            ))
        }).store(in: &cancellables)

        roster.eventPublisher.sink(receiveValue: { [weak self] event in
            guard let self = self else { return }

            let senderName = "Chatbot"

            switch event {
            case .added(let participant):
                self.messages.append(Message(
                    title: senderName,
                    text: "\(participant.displayName) joined"
                ))
            case .deleted(let participant):
                self.messages.append(Message(
                    title: senderName,
                    text: "\(participant.displayName) left"
                ))
            case .updated, .reloaded:
                break
            }
        }).store(in: &cancellables)
    }
}

// MARK: - Message

extension ChatViewModel {
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
