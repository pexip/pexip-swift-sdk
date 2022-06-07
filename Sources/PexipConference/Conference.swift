import Foundation
import Combine
import PexipMedia
import PexipInfinityClient
import PexipUtils

// MARK: - Protocol

/// Conference is responsible for media signaling, token refreshing
/// and handling of the conference events.
public protocol Conference {
    /// The object that acts as the delegate of the conference.
    var delegate: ConferenceDelegate? { get set }
    /// The publisher that publishes conference events
    var eventPublisher: AnyPublisher<ConferenceEvent, Never> { get }
    /// The object responsible for setting up and controlling a communication session
    var signaling: MediaConnectionSignaling { get }
    /// The object responsible for sending and receiving text messages in the conference
    var chat: Chat? { get }
    // The full participant list of the conference
    var roster: Roster { get }
    /// Starts receiving conference events as they occur
    func receiveEvents() async
    /// Leaves the conference. Once left, the ``Conference`` object is no longer valid.
    func leave() async throws
}

// MARK: - Implementation

final class InfinityConference: Conference {
    weak var delegate: ConferenceDelegate?
    var eventPublisher: AnyPublisher<ConferenceEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    let signaling: MediaConnectionSignaling
    let chat: Chat?
    let roster: Roster

    private let conferenceName: String
    private let tokenRefresher: TokenRefresher
    private let eventSource: EventSource
    private let logger: Logger?
    private let isClientDisconnected = Isolated(false)
    private var eventSourceTask: Task<Void, Never>?
    private var eventSubject = PassthroughSubject<ConferenceEvent, Never>()

    // MARK: - Init

    init(
        conferenceName: String,
        tokenRefresher: TokenRefresher,
        signaling: MediaConnectionSignaling,
        eventSource: EventSource,
        chat: Chat?,
        roster: Roster,
        logger: Logger?
    ) {
        self.conferenceName = conferenceName
        self.tokenRefresher = tokenRefresher
        self.signaling = signaling
        self.eventSource = eventSource
        self.chat = chat
        self.roster = roster
        self.logger = logger

        Task {
            await tokenRefresher.startRefreshing()
        }

        logger?.info("Joining \(conferenceName) as an API client")
    }

    // MARK: - Public API

    func receiveEvents() async {
        guard await !eventSource.isOpen, await !isClientDisconnected.value else {
            return
        }

        await eventSource.open()
        eventSourceTask = Task {
            for await message in await eventSource.messages() {
                await handleServerMessage(message)
            }
        }
    }

    func leave() async throws {
        logger?.info("Leaving \(conferenceName)")
        eventSourceTask?.cancel()
        await roster.clear()
        await eventSource.close()
        await tokenRefresher.endRefreshing(
            withTokenRelease: await !isClientDisconnected.value
        )
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
