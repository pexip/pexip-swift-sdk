import Foundation

// MARK: - Protocol

public protocol ConferenceProtocol {
    func join() async throws
    func leave() async throws
}

// MARK: - Implementation

final class Conference: ConferenceProtocol {
    private let conferenceName: String
    private let userDisplayName: String
    private let tokenSession: TokenSessionProtocol
    private let callSession: CallSessionProtocol
    private let eventSource: ConferenceEventSourceProtocol
    private let logger: LoggerProtocol
    private var eventStreamTask: Task<Void, Never>?

    // MARK: - Init

    init(
        conferenceName: String,
        userDisplayName: String,
        tokenSession: TokenSessionProtocol,
        callSession: CallSessionProtocol,
        eventSource: ConferenceEventSourceProtocol,
        logger: LoggerProtocol
    ) {
        self.conferenceName = conferenceName
        self.userDisplayName = userDisplayName
        self.tokenSession = tokenSession
        self.callSession = callSession
        self.eventSource = eventSource
        self.logger = logger
        setup()
    }

    // MARK: - Public API

    func join() async throws {
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

    private func setup() {
        Task {
            try await tokenSession.activate()
            try await eventSource.open()

            eventStreamTask = Task {
                for await event in await eventSource.eventStream() {
                    handleEvent(event)
                }
            }
        }
    }

    private func handleEvent(_ event: ConferenceEvent) {
        switch event {
        case .chatMessage:
            break
        }
    }
}
