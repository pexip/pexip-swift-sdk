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
    private let serverEventSession: ServerEventSession
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
        serverEventSession: ServerEventSession,
        logger: LoggerProtocol
    ) {
        self.conferenceName = conferenceName
        self.userDisplayName = userDisplayName
        self.tokenSession = tokenSession
        self.callSession = callSession
        self.serverEventSession = serverEventSession
        self.logger = logger
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

        callSession.eventPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.handleCallEvent(event)
            }
            .store(in: &cancellables)

        logger[.conference].info(
            "Joining \(conferenceName) as \(userDisplayName)"
        )

        do {
            try await callSession.start()
        } catch {
            await cleanup(releaseToken: true)
            throw error
        }
    }

    func leave() async throws {
        guard await tokenSession.isActive else {
            throw ConferenceError.cannotLeaveInactiveConference
        }

        logger[.conference].info("Leaving \(conferenceName)")
        await cleanup(releaseToken: true)
    }

    // MARK: - Private methods

    @MainActor
    private func handleServerMessage(_ message: ServerEvent.Message) {
        Task {
            switch message {
            case .chat:
                logger[.conference].debug("Chat message received")
            case .callDisconnected(let info):
                logger[.conference].debug("Call disconnected, reason: \(info.reason)")
            case .disconnect(let info):
                await cleanup(releaseToken: false)
                callDelegate?.conferenceDidDisconnect(self)
                callEventSubject.send(.disconnected)
                logger[.conference].debug("Participant disconnected, reason: \(info.reason)")
            }
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

    private func cleanup(releaseToken: Bool) async {
        eventStreamTask?.cancel()
        await serverEventSession.close()
        await tokenSession.deactivate(releaseToken: releaseToken)
        await callSession.stop()
    }
}

// MARK: - Errors

public enum ConferenceError: LocalizedError, CustomStringConvertible {
    case cannotJoinActiveConference
    case cannotLeaveInactiveConference

    public var description: String {
        switch self {
        case .cannotJoinActiveConference:
            return "Cannot join already active conference"
        case .cannotLeaveInactiveConference:
            return "Cannot leave already inactive conference"
        }
    }
}
