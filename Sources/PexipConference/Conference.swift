import Foundation
import Combine
import PexipMedia
import PexipInfinityClient
import PexipUtils

// MARK: - Protocol

public protocol Conference {
    var delegate: ConferenceDelegate? { get set }
    var eventPublisher: AnyPublisher<ConferenceEvent, Never> { get }
    var mainSignaling: MediaConnectionSignaling { get }
    @available(*, deprecated, message: "Will be deprecated in future version")
    var presentationSignaling: MediaConnectionSignaling { get }
    var chat: Chat? { get }
    var roster: Roster { get }
    func leave() async throws
}

// MARK: - Implementation

final class InfinityConference: Conference {
    weak var delegate: ConferenceDelegate?
    var eventPublisher: AnyPublisher<ConferenceEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    let mainSignaling: MediaConnectionSignaling
    @available(*, deprecated, message: "Will be deprecated in future versions")
    let presentationSignaling: MediaConnectionSignaling
    let chat: Chat?
    let roster: Roster

    private let conferenceName: String
    private let tokenRefresher: TokenRefresher
    private let eventSource: EventSource
    private let logger: Logger?
    private var eventStreamTask: Task<Void, Never>?
    private var eventSubject = PassthroughSubject<ConferenceEvent, Never>()

    // MARK: - Init

    init(
        conferenceName: String,
        tokenRefresher: TokenRefresher,
        mainSignaling: MediaConnectionSignaling,
        presentationSignaling: MediaConnectionSignaling,
        eventSource: EventSource,
        chat: Chat?,
        roster: Roster,
        logger: Logger?
    ) {
        self.conferenceName = conferenceName
        self.tokenRefresher = tokenRefresher
        self.mainSignaling = mainSignaling
        self.presentationSignaling = presentationSignaling
        self.eventSource = eventSource
        self.chat = chat
        self.roster = roster
        self.logger = logger

        Task {
            await setup()
        }
    }

    // MARK: - Public API

    func leave() async throws {
        logger?.info("Leaving \(conferenceName)")
        await leave(withTokenRelease: true)
    }

    // MARK: - Setup

    private func setup() async {
        await tokenRefresher.startRefreshing()
        await eventSource.open()
        eventStreamTask = Task {
            for await message in await eventSource.messages() {
                await handleServerMessage(message)
            }
        }
        logger?.info("Joining \(conferenceName)")
    }

    private func leave(withTokenRelease: Bool) async {
        eventStreamTask?.cancel()
        await roster.clear()
        await eventSource.close()
        await tokenRefresher.endRefreshing(withTokenRelease: withTokenRelease)
    }

    // MARK: - Server events

    @MainActor
    private func handleServerMessage(_ message: ServerEvent.Message) {
        Task {
            switch message {
            case .presentationStarted(let details):
                sendEvent(.presentationStarted(details))
            case .presentationStopped:
                sendEvent(.presentationStopped)
            case .chat(let message):
                logger?.debug("Chat message received")
                await chat?.addMessage(message)
            case .participantSyncBegan:
                logger?.debug("Participant sync began")
                await roster.setSyncing(true)
            case .participantSyncEnded:
                logger?.debug("Participant sync ended")
                await roster.setSyncing(false)
            case .participantCreated(let participant):
                logger?.debug("Participant added")
                await roster.addParticipant(participant)
            case .participantUpdated(let participant):
                logger?.debug("Participant updated")
                await roster.updateParticipant(participant)
            case .participantDeleted(let details):
                logger?.debug("Participant deleted")
                await roster.removeParticipant(withId: details.id)
            case .callDisconnected(let details):
                logger?.debug("Call disconnected, reason: \(details.reason)")
            case .clientDisconnected(let details):
                await leave(withTokenRelease: false)
                logger?.debug("Participant disconnected, reason: \(details.reason)")
            }
        }
    }

    // MARK: - Conference events

    private func sendEvent(_ event: ConferenceEvent) {
        Task { @MainActor in
            delegate?.conference(self, didReceiveEvent: event)
            eventSubject.send(event)
        }
    }
}
