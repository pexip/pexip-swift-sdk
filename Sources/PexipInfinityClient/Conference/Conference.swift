import Foundation
import Combine
import PexipCore

// MARK: - Protocol

/// Conference is responsible for media signaling, token refreshing
/// and handling of the conference events.
public protocol Conference {
    /// The object that acts as the delegate of the conference.
    var delegate: ConferenceDelegate? { get set }

    /// The publisher that publishes conference events
    var eventPublisher: AnyPublisher<ConferenceEvent, Never> { get }

    /// The object responsible for setting up and controlling a communication session
    var signalingChannel: SignalingChannel { get }

    /// The full participant list of the conference
    var roster: Roster { get }

    /// The object responsible for sending and receiving text messages in the conference
    var chat: Chat? { get }

    /// Starts receiving conference events as they occur
    func receiveEvents() async

    /// Starts/stops receiving live caption events.
    @discardableResult
    func toggleLiveCaptions(_ show: Bool) async throws -> Bool

    /// Leaves the conference. Once left, the ``Conference`` object is no longer valid.
    func leave() async throws
}

// MARK: - Implementation

final class DefaultConference: Conference {
    weak var delegate: ConferenceDelegate?
    var eventPublisher: AnyPublisher<ConferenceEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    let signalingChannel: SignalingChannel
    let roster: Roster
    let chat: Chat?

    private typealias EventSourceTask = Task<Void, Never>

    private let tokenStore: TokenStore<ConferenceToken>
    private let tokenRefresher: TokenRefresher
    private let eventSource: InfinityEventSource<ConferenceEvent>
    private let liveCaptionsService: LiveCaptionsService
    private let logger: Logger?
    private let isClientDisconnected = Isolated(false)
    private let eventSourceTask = Isolated<EventSourceTask?>(nil)
    private var eventSubject = PassthroughSubject<ConferenceEvent, Never>()
    private let status = Isolated<ConferenceStatus?>(nil)
    // Skip initial `presentation_stop` event
    private let skipPresentationStop = Isolated(true)

    // MARK: - Init

    init(
        tokenStore: TokenStore<ConferenceToken>,
        tokenRefresher: TokenRefresher,
        signalingChannel: SignalingChannel,
        eventSource: InfinityEventSource<ConferenceEvent>,
        roster: Roster,
        liveCaptionsService: LiveCaptionsService,
        chat: Chat?,
        logger: Logger?
    ) {
        self.tokenStore = tokenStore
        self.tokenRefresher = tokenRefresher
        self.signalingChannel = signalingChannel
        self.eventSource = eventSource
        self.roster = roster
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
        guard await eventSourceTask.value == nil else {
            return
        }

        guard await !isClientDisconnected.value else {
            return
        }

        await skipPresentationStop.setValue(true)

        await eventSourceTask.setValue(Task {
            for await event in eventSource.events() {
                await handleEvent(event)
            }
        })
    }

    @discardableResult
    func toggleLiveCaptions(_ enabled: Bool) async throws -> Bool {
        guard let status = await status.value, status.liveCaptionsAvailable else {
            return false
        }

        let token = try await tokenStore.token()
        try await liveCaptionsService.toggleLiveCaptions(enabled, token: token)
        return true
    }

    func leave() async throws {
        logger?.info("Leaving the conference")
        await eventSourceTask.value?.cancel()
        await eventSourceTask.setValue(nil)
        await roster.clear()
        await tokenRefresher.endRefreshing(
            withTokenRelease: await !isClientDisconnected.value
        )
    }

    // MARK: - Events

    // swiftlint:disable cyclomatic_complexity
    private func handleEvent(_ event: ConferenceEvent) async {
        if case .presentationStop = event, await skipPresentationStop.value {
            await skipPresentationStop.setValue(false)
            return
        }

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

    private func sendEvent(_ event: ConferenceEvent) {
        Task { @MainActor in
            delegate?.conference(self, didReceiveEvent: event)
            eventSubject.send(event)
        }
    }
}
