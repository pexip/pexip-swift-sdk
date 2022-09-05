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

    /// Receives conference events as they occur
    /// - Returns: False if has already subscribed to the event source
    ///            or client was disconnected, True otherwise
    @discardableResult
    func receiveEvents() -> Bool

    /// Starts/stops receiving live caption events.
    @discardableResult
    func toggleLiveCaptions(_ show: Bool) async throws -> Bool

    /// Leaves the conference. Once left, the ``Conference`` object is no longer valid.
    func leave() async
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
    var isClientDisconnected: Bool { _isClientDisconnected.value }
    var status: ConferenceStatus? { _status.value }

    private typealias EventSourceTask = Task<Void, Never>

    private let tokenStore: TokenStore<ConferenceToken>
    private let tokenRefresher: TokenRefresher
    private let eventSource: InfinityEventSource<ConferenceEvent>
    private let liveCaptionsService: LiveCaptionsService
    private let logger: Logger?
    private let eventSourceTask = Synchronized<EventSourceTask?>(nil)
    private var eventSubject = PassthroughSubject<ConferenceEvent, Never>()
    // Skip initial `presentation_stop` event
    private let skipPresentationStop = Synchronized(true)
    private let _status = Synchronized<ConferenceStatus?>(nil)
    private let _isClientDisconnected = Synchronized(false)

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
            await tokenRefresher.startRefreshing(onError: { error in
                Task { [weak self] in
                    await self?.sendEvent(.failure(FailureEvent(error: error)))
                }
            })
        }

        logger?.info("Joining the conference as an API client")
    }

    // MARK: - Public API

    @discardableResult
    func receiveEvents() -> Bool {
        guard eventSourceTask.value == nil else {
            return false
        }

        guard !_isClientDisconnected.value else {
            return false
        }

        skipPresentationStop.setValue(true)

        eventSourceTask.setValue(Task {
            do {
                for try await event in eventSource.events() {
                    await handleEvent(event)
                }
            } catch {
                eventSourceTask.setValue(nil)
                await handleEvent(.failure(FailureEvent(error: error)))
            }
        })

        return true
    }

    @discardableResult
    func toggleLiveCaptions(_ enabled: Bool) async throws -> Bool {
        guard let status = status, status.liveCaptionsAvailable else {
            return false
        }

        let token = try await tokenStore.token()
        try await liveCaptionsService.toggleLiveCaptions(enabled, token: token)
        return true
    }

    func leave() async {
        logger?.info("Leaving the conference")
        eventSourceTask.value?.cancel()
        eventSourceTask.setValue(nil)
        await tokenRefresher.endRefreshing(
            withTokenRelease: !isClientDisconnected
        )
        await roster.clear()
    }

    // MARK: - Events

    // swiftlint:disable cyclomatic_complexity
    private func handleEvent(_ event: ConferenceEvent) async {
        if case .presentationStop = event, skipPresentationStop.value {
            skipPresentationStop.setValue(false)
            return
        }

        switch event {
        case .conferenceUpdate(let value):
            _status.setValue(value)
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
            _isClientDisconnected.setValue(true)
            logger?.debug("Participant disconnected, reason: \(details.reason)")
        default:
            break
        }

        await sendEvent(event)
    }

    @MainActor
    private func sendEvent(_ event: ConferenceEvent) {
        delegate?.conference(self, didReceiveEvent: event)
        eventSubject.send(event)
    }
}
