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
    var chat: Chat? { get }
    var roster: Roster { get }
    func join() async
    func leave() async throws
}

// MARK: - Implementation

final class InfinityConference: Conference {
    weak var delegate: ConferenceDelegate?
    var eventPublisher: AnyPublisher<ConferenceEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    let mainSignaling: MediaConnectionSignaling
    let chat: Chat?
    let roster: Roster

    private let conferenceName: String
    private let tokenRefresher: TokenRefresher
    private let eventSource: EventSource
    private let logger: Logger?
    private var eventSourceTask: Task<Void, Never>?
    private var eventSubject = PassthroughSubject<ConferenceEvent, Never>()
    private var isActive = Isolated(false)
    private var isClientDisconnected = Isolated(false)

    // MARK: - Init

    init(
        conferenceName: String,
        tokenRefresher: TokenRefresher,
        mainSignaling: MediaConnectionSignaling,
        eventSource: EventSource,
        chat: Chat?,
        roster: Roster,
        logger: Logger?
    ) {
        self.conferenceName = conferenceName
        self.tokenRefresher = tokenRefresher
        self.mainSignaling = mainSignaling
        self.eventSource = eventSource
        self.chat = chat
        self.roster = roster
        self.logger = logger

        Task {
            await tokenRefresher.startRefreshing()
        }
    }

    // MARK: - Public API

    func join() async {
        guard await !isActive.value, await !isClientDisconnected.value else {
            return
        }

        await eventSource.open()
        eventSourceTask = Task {
            for await message in await eventSource.messages() {
                await handleServerMessage(message)
            }
        }
        logger?.info("Joining \(conferenceName)")
        await isActive.setValue(true)
    }

    func leave() async throws {
        guard await isActive.value else {
            return
        }

        logger?.info("Leaving \(conferenceName)")
        eventSourceTask?.cancel()
        await roster.clear()
        await eventSource.close()
        await tokenRefresher.endRefreshing(
            withTokenRelease: await !isClientDisconnected.value
        )
        await isActive.setValue(false)
    }

    // MARK: - Private methods

    private func leave(withTokenRelease: Bool) async {

    }

    // MARK: - Server events

    @MainActor
    private func handleServerMessage(_ message: ServerEvent.Message) {
        Task {
            switch message {
            case .presentationStart(let details):
                sendEvent(.presentationStart(details))
            case .presentationStop:
                sendEvent(.presentationStop)
            case .messageReceived(let message):
                logger?.debug("Chat message received")
                await chat?.addMessage(message)
            case .participantSyncBegin:
                logger?.debug("Participant sync began")
                await roster.setSyncing(true)
            case .participantSyncEnd:
                logger?.debug("Participant sync ended")
                await roster.setSyncing(false)
            case .participantCreate(let participant):
                logger?.debug("Participant added")
                await roster.addParticipant(participant)
            case .participantUpdate(let participant):
                logger?.debug("Participant updated")
                await roster.updateParticipant(participant)
            case .participantDelete(let details):
                logger?.debug("Participant deleted")
                await roster.removeParticipant(withId: details.id)
            case .callDisconnected(let details):
                logger?.debug("Call disconnected, reason: \(details.reason)")
            case .clientDisconnected(let details):
                await isClientDisconnected.setValue(true)
                sendEvent(.clientDisconnected)
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
