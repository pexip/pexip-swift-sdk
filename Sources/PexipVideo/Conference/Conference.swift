import Foundation
import Combine

// MARK: - Protocol

public protocol ConferenceProtocol {
    var mediaDelegate: ConferenceMediaDelegate? { get set }
    var mediaEventPublisher: AnyPublisher<ConferenceMediaEvent, Never> { get }

    var callDelegate: ConferenceCallDelegate? { get set }
    var callEventPublisher: AnyPublisher<ConferenceCallEvent, Never> { get }

    var audioTrack: AudioTrackProtocol? { get }
    var localVideoTrack: LocalVideoTrackProtocol? { get }
    var remoteVideoTrack: VideoTrackProtocol? { get }

    func join() async throws
    func leave() async throws
}

// MARK: - Implementation

final class Conference: ConferenceProtocol {
    weak var mediaDelegate: ConferenceMediaDelegate?
    var mediaEventPublisher: AnyPublisher<ConferenceMediaEvent, Never> {
        mediaEventSubject.eraseToAnyPublisher()
    }

    weak var callDelegate: ConferenceCallDelegate?
    var callEventPublisher: AnyPublisher<ConferenceCallEvent, Never> {
        callEventSubject.eraseToAnyPublisher()
    }

    var audioTrack: AudioTrackProtocol? { callSession.audioTrack }
    var localVideoTrack: LocalVideoTrackProtocol? { callSession.localVideoTrack }
    var remoteVideoTrack: VideoTrackProtocol? { callSession.remoteVideoTrack }

    private let conferenceName: String
    private let userDisplayName: String
    private let tokenSession: TokenSessionProtocol
    private let callSession: CallSessionProtocol
    private let eventSource: ServerSentEventSourceProtocol
    private let logger: LoggerProtocol
    private var eventStreamTask: Task<Void, Never>?
    private var mediaEventSubject = PassthroughSubject<ConferenceMediaEvent, Never>()
    private var callEventSubject = PassthroughSubject<ConferenceCallEvent, Never>()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init(
        conferenceName: String,
        userDisplayName: String,
        tokenSession: TokenSessionProtocol,
        callSession: CallSessionProtocol,
        eventSource: ServerSentEventSourceProtocol,
        logger: LoggerProtocol
    ) {
        self.conferenceName = conferenceName
        self.userDisplayName = userDisplayName
        self.tokenSession = tokenSession
        self.callSession = callSession
        self.eventSource = eventSource
        self.logger = logger
    }

    // MARK: - Public API

    func join() async throws {
        Task {
            try await tokenSession.activate()
            try await eventSource.open()

            eventStreamTask = Task {
                for await event in await eventSource.eventStream() {
                    await handleConferenceEvent(event)
                }
            }
        }

        callSession.eventPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.handleCallEvent(event)
            }
            .store(in: &cancellables)

        logger[.conference].info(
            "Joining \(conferenceName) as \(userDisplayName)"
        )
        try await callSession.start()
    }

    func leave() async throws {
        logger[.conference].info("Leaving \(conferenceName)")
        eventStreamTask?.cancel()
        await eventSource.close()
        try await callSession.stop()
        try await tokenSession.deactivate()
    }

    // MARK: - Private methods

    @MainActor
    private func handleConferenceEvent(_ event: ServerSentEvent) {
        switch event {
        case .chatMessage:
            logger[.conference].debug("Chat message received")
        case .callDisconnected(let info):
            logger[.conference].debug("Call disconnected, reason: \(info.reason)")
        case .disconnect(let info):
            callDelegate?.conferenceDidDisconnect(self)
            callEventSubject.send(.disconnected)
            logger[.conference].debug("Participant disconnected, reason: \(info.reason)")
        }
    }

    private func handleCallEvent(_ event: CallEvent) {
        switch event {
        case .mediaStarted:
            mediaDelegate?.conferenceDidStartMedia(self)
            mediaEventSubject.send(.started)
        case .mediaEnded:
            mediaDelegate?.conferenceDidEndMedia(self)
            mediaEventSubject.send(.ended)
        }
    }
}
