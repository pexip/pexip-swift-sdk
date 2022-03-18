import Foundation
import Combine

// MARK: - Protocol

public protocol ConferenceProtocol {
    var callDelegate: ConferenceCallDelegate? { get set }
    var callEventPublisher: AnyPublisher<CallEvent, Never> { get }

    var presentationDelegate: ConferencePresentationDelegate? { get set }
    var presentationEventPublisher: AnyPublisher<PresentationEvent, Never> { get }

    var chat: Chat? { get }
    var roster: Roster { get }

    var audioTrack: LocalAudioTrackProtocol? { get }
    var localVideoTrack: LocalVideoTrackProtocol? { get }
    var remoteVideoTrack: VideoTrackProtocol? { get }

    func join() async throws
    func leave() async throws
}

// MARK: - Implementation

final class Conference: ConferenceProtocol {
    weak var callDelegate: ConferenceCallDelegate?
    var callEventPublisher: AnyPublisher<CallEvent, Never> {
        callEventSubject.eraseToAnyPublisher()
    }

    weak var presentationDelegate: ConferencePresentationDelegate?
    var presentationEventPublisher: AnyPublisher<PresentationEvent, Never> {
        presentationEventSubject.eraseToAnyPublisher()
    }

    let chat: Chat?
    let roster: Roster
    var audioTrack: LocalAudioTrackProtocol? { callTransceiver.audioTrack }
    var localVideoTrack: LocalVideoTrackProtocol? { callTransceiver.localVideoTrack }
    var remoteVideoTrack: VideoTrackProtocol? { callTransceiver.remoteVideoTrack }

    private let conferenceName: String
    private let userDisplayName: String
    private let tokenSession: TokenSessionProtocol
    private let callSessionFactory: CallSessionFactoryProtocol
    private let callTransceiver: CallSessionProtocol
    private var presentationReceiver: CallSessionProtocol?
    private let serverEventSession: ServerEventSession
    private let logger: LoggerProtocol
    private var eventStreamTask: Task<Void, Never>?
    private var callEventSubject = PassthroughSubject<CallEvent, Never>()
    private var presentationEventSubject = PassthroughSubject<PresentationEvent, Never>()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init(
        conferenceName: String,
        userDisplayName: String,
        tokenSession: TokenSessionProtocol,
        callSessionFactory: CallSessionFactoryProtocol,
        serverEventSession: ServerEventSession,
        chat: Chat?,
        roster: Roster,
        logger: LoggerProtocol
    ) {
        self.conferenceName = conferenceName
        self.userDisplayName = userDisplayName
        self.tokenSession = tokenSession
        self.callSessionFactory = callSessionFactory
        self.callTransceiver = callSessionFactory.callTransceiver()
        self.serverEventSession = serverEventSession
        self.logger = logger
        self.chat = chat
        self.roster = roster
    }

    // MARK: - Public API

    func join() async throws {
        guard await !tokenSession.isActive else {
            throw ConferenceError.cannotJoinActiveConference
        }

        await tokenSession.activate()
        await serverEventSession.open()

        eventStreamTask = Task {
            for await message in await serverEventSession.messages() {
                await handleServerMessage(message)
            }
        }

        logger[.conference].info(
            "Joining \(conferenceName) as \(userDisplayName)"
        )

        try await startCallTransceiver()
    }

    func leave() async throws {
        guard await tokenSession.isActive else {
            throw ConferenceError.cannotLeaveInactiveConference
        }

        logger[.conference].info("Leaving \(conferenceName)")
        await cleanup(releaseToken: true)
    }

    // MARK: - Server events

    @MainActor
    private func handleServerMessage(_ message: ServerEvent.Message) {
        Task {
            switch message {
            case .presentationStarted(let details):
                await startPresentationReceiver(details: details)
            case .presentationStopped:
                await stopPresentationReceiver()
            case .chat(let message):
                logger[.conference].debug("Chat message received")
                await chat?.addMessage(message)
            case .participantSyncBegan:
                logger[.conference].debug("Participant sync began")
                await roster.setSyncing(true)
            case .participantSyncEnded:
                logger[.conference].debug("Participant sync ended")
                await roster.setSyncing(false)
            case .participantCreated(let participant):
                logger[.conference].debug("Participant added")
                await roster.addParticipant(participant)
            case .participantUpdated(let participant):
                logger[.conference].debug("Participant updated")
                await roster.updateParticipant(participant)
            case .participantDeleted(let details):
                logger[.conference].debug("Participant deleted")
                await roster.removeParticipant(withId: details.uuid)
            case .callDisconnected(let details):
                logger[.conference].debug("Call disconnected, reason: \(details.reason)")
            case .clientDisconnected(let details):
                await cleanup(releaseToken: false)
                logger[.conference].debug("Participant disconnected, reason: \(details.reason)")
            }
        }
    }

    // MARK: - Cleanup

    private func cleanup(releaseToken: Bool) async {
        eventStreamTask?.cancel()
        await roster.clear()
        await serverEventSession.close()
        await callTransceiver.stop()
        await presentationReceiver?.stop()
        await tokenSession.deactivate(releaseToken: releaseToken)
    }

    // MARK: - Audio/Video Call

    private func startCallTransceiver() async throws {
        callTransceiver.eventPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.sendCallEvent(event)
            }
            .store(in: &cancellables)

        do {
            try await callTransceiver.start()
        } catch {
            await cleanup(releaseToken: true)
            throw error
        }
    }

    // MARK: - Remote presentation

    private func startPresentationReceiver(details: PresentationDetails) async {
        let presentationReceiver = callSessionFactory.presentationReceiver()
        self.presentationReceiver = presentationReceiver

        presentationReceiver.eventPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.handlePresentationReceiverEvent(event, details: details)
            }
            .store(in: &cancellables)

        do {
            try await presentationReceiver.start()
        } catch {
            await stopPresentationReceiver()
            logger[.conference].error("Cannot receive presentation, error: \(error)")
        }
    }

    private func stopPresentationReceiver() async {
        await presentationReceiver?.stop()
        presentationReceiver = nil
    }

    private func handlePresentationReceiverEvent(
        _ event: CallEvent,
        details: PresentationDetails
    ) {
        switch event {
        case .connected:
            if let track = presentationReceiver?.remoteVideoTrack {
                sendPresentationEvent(.started(track: track, details: details))
            }
        case .failed:
            sendPresentationEvent(.failed)
        case .disconnected, .closed:
            sendPresentationEvent(.stopped)
        }
    }

    // MARK: - Conference events

    private func sendCallEvent(_ event: CallEvent) {
        Task { @MainActor in
            callDelegate?.conference(self, didReceiveCallEvent: event)
            callEventSubject.send(event)
        }
    }

    private func sendPresentationEvent(_ event: PresentationEvent) {
        Task { @MainActor in
            presentationDelegate?.conference(self, didReceivePresentationEvent: event)
            presentationEventSubject.send(event)
        }
    }
}
