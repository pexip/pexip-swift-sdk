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

    /// The full participant list of the conference
    var roster: Roster { get }

    /// The object responsible for sending and receiving text messages in the conference
    var chat: Chat? { get }

    /// Starts receiving conference events as they occur
    func receiveEvents() async

    /// Starts/stops receiving live caption events.
    @discardableResult
    func toggleLiveCaptions(_ show: Bool) async throws -> Bool

    /// Sends DTMF signals to the participant.
    @discardableResult
    func dtmf(signals: DTMFSignals) async throws -> Bool

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
    let roster: Roster
    let chat: Chat?

    private let tokenRefresher: TokenRefresher
    private let eventSource: ConferenceEventSource
    private let dtmfSender: DTMFSender
    private let liveCaptionsService: LiveCaptionsService
    private let logger: Logger?
    private let isClientDisconnected = Isolated(false)
    private var eventSourceTask: Task<Void, Never>?
    private var eventSubject = PassthroughSubject<ConferenceEvent, Never>()
    private let status = Isolated<ConferenceStatus?>(nil)

    // MARK: - Init

    init(
        tokenRefresher: TokenRefresher,
        signaling: MediaConnectionSignaling,
        eventSource: ConferenceEventSource,
        roster: Roster,
        dtmfSender: DTMFSender,
        liveCaptionsService: LiveCaptionsService,
        chat: Chat?,
        logger: Logger?
    ) {
        self.tokenRefresher = tokenRefresher
        self.signaling = signaling
        self.eventSource = eventSource
        self.roster = roster
        self.dtmfSender = dtmfSender
        self.liveCaptionsService = liveCaptionsService
        self.chat = chat
        self.logger = logger

        Task {
            await tokenRefresher.startRefreshing()
        }

        logger?.info("Joining the conference as an API client")
    }

    // MARK: - Public API

    func receiveEvents() async {
        guard await !eventSource.isOpen, await !isClientDisconnected.value else {
            return
        }

        await eventSource.open()
        eventSourceTask = Task {
            for await event in await eventSource.events() {
                await handleConferenceEvent(event)
            }
        }
    }

    @discardableResult
    func toggleLiveCaptions(_ show: Bool) async throws -> Bool {
        if let status = await status.value {
            return try await liveCaptionsService.toggleLiveCaptions(
                show,
                conferenceStatus: status
            )
        } else {
            return false
        }
    }

    @discardableResult
    func dtmf(signals: DTMFSignals) async throws -> Bool {
        try await dtmfSender.send(dtmf: signals)
    }

    func leave() async throws {
        logger?.info("Leaving the conference")
        eventSourceTask?.cancel()
        await roster.clear()
        await eventSource.close()
        await tokenRefresher.endRefreshing(
            withTokenRelease: await !isClientDisconnected.value
        )
    }

    // MARK: - Events

    @MainActor
    private func handleConferenceEvent(_ event: ConferenceEvent) {
        Task {
            switch event {
            case .conferenceUpdate(let value):
                await status.setValue(value)
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
                logger?.debug("Participant disconnected, reason: \(details.reason)")
            default:
                break
            }

            sendEvent(event)
        }
    }

    private func sendEvent(_ event: ConferenceEvent) {
        Task { @MainActor in
            delegate?.conference(self, didReceiveEvent: event)
            eventSubject.send(event)
        }
    }
}
