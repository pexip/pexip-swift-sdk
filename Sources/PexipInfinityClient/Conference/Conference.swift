import Foundation
import Combine
import PexipCore

// MARK: - Protocol

/// Conference is responsible for media signaling, token refreshing
/// and handling of the conference events.
public protocol Conference: AnyObject {
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

    /// All available conference splash screens
    var splashScreens: [String: SplashScreen] { get }

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
    var splashScreens = [String: SplashScreen]()
    var isClientDisconnected: Bool { _isClientDisconnected.value }
    var status: ConferenceStatus? { _status.value }

    private typealias EventSourceTask = Task<Void, Never>

    private let tokenStore: TokenStore<ConferenceToken>
    private let connection: InfinityConnection<ConferenceEvent>
    private let splashScreenService: SplashScreenService
    private let liveCaptionsService: LiveCaptionsService
    private let logger: Logger?
    private var eventSubject = PassthroughSubject<ConferenceEvent, Never>()
    private var eventTask: Task<Void, Never>?
    // Skip initial `presentation_stop` event
    private let skipPresentationStop = Synchronized(true)
    private let hasRequestedSplashScreens = Synchronized(false)
    private let _status = Synchronized<ConferenceStatus?>(nil)
    private let _isClientDisconnected = Synchronized(false)

    // MARK: - Init

    init(
        connection: InfinityConnection<ConferenceEvent>,
        tokenStore: TokenStore<ConferenceToken>,
        signalingChannel: SignalingChannel,
        roster: Roster,
        splashScreenService: SplashScreenService,
        liveCaptionsService: LiveCaptionsService,
        chat: Chat?,
        logger: Logger?
    ) {
        self.connection = connection
        self.tokenStore = tokenStore
        self.signalingChannel = signalingChannel
        self.roster = roster
        self.splashScreenService = splashScreenService
        self.liveCaptionsService = liveCaptionsService
        self.chat = chat
        self.logger = logger

        eventTask = Task { [weak self] in
            guard let events = self?.connection.events() else {
                return
            }

            for await event in events {
                do {
                    await self?.handleEvent(try event.get())
                } catch {
                    await self?.handleEvent(
                        .failure(FailureEvent(error: error))
                    )
                }
            }
        }

        logger?.info("Joining the conference as an API client")
    }

    deinit {
        cancelTasks()
    }

    // MARK: - Public API

    @discardableResult
    func receiveEvents() -> Bool {
        guard !isClientDisconnected else {
            return false
        }

        if connection.receiveEvents() {
            skipPresentationStop.setValue(true)
            return true
        }

        return false
    }

    @discardableResult
    func toggleLiveCaptions(_ enabled: Bool) async throws -> Bool {
        guard let status, status.liveCaptionsAvailable else {
            return false
        }

        let token = try await tokenStore.token()
        try await liveCaptionsService.toggleLiveCaptions(enabled, token: token)
        return true
    }

    func leave() async {
        logger?.info("Leaving the conference")
        cancelTasks()
        await roster.clear()
    }

    // MARK: - Private

    private func cancelTasks() {
        eventTask?.cancel()
        eventTask = nil
        connection.cancel(withTokenRelease: !isClientDisconnected)
    }

    private func loadSplashScreensIfNeeded() async {
        guard !hasRequestedSplashScreens.value else {
            return
        }

        do {
            let token = try await tokenStore.token()
            splashScreens = try await splashScreenService.splashScreens(token: token)
        } catch {
            logger?.error("Failed to load conference splash screens: \(error)")
        }

        hasRequestedSplashScreens.setValue(true)
    }

    // swiftlint:disable cyclomatic_complexity
    @MainActor
    private func handleEvent(_ event: ConferenceEvent) async {
        if case .presentationStop = event, skipPresentationStop.value {
            skipPresentationStop.setValue(false)
            return
        }

        var event = event

        switch event {
        case .splashScreen(var splashScreen):
            if let key = splashScreen?.key {
                await loadSplashScreensIfNeeded()
                splashScreen?.splashScreen = splashScreens[key]
            }
            event = .splashScreen(splashScreen)
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

        delegate?.conference(self, didReceiveEvent: event)
        eventSubject.send(event)
    }
}
