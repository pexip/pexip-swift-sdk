import Foundation
import PexipInfinityClient
import PexipUtils

// MARK: - Protocol

protocol ConferenceEventSource {
    var isOpen: Bool { get async }
    func events() async -> AsyncStream<ConferenceEvent>
    func open() async
    func close() async
}

// MARK: - Implementation

actor DefaultConferenceEventSource: ConferenceEventSource {
    var isOpen: Bool { get async { eventSourceTask?.isCancelled == false } }

    private let decoder = JSONDecoder()
    private let service: ConferenceEventService
    private let tokenStore: TokenStore
    private let logger: Logger?
    private let maxReconnectionTime: TimeInterval = 5
    private var reconnectionTime: TimeInterval = 1
    private var reconnectionAttempts: Int = 0
    private var eventSourceTask: Task<Void, Error>?
    private var subscribers = [AsyncStream<ConferenceEvent>.Continuation]()
    // Skip initial `presentation_stop` event
    var skipPresentationStop = true

    // MARK: - Init

    init(
        service: ConferenceEventService,
        tokenStore: TokenStore,
        logger: Logger? = nil
    ) {
        self.service = service
        self.tokenStore = tokenStore
        self.logger = logger
    }

    // MARK: - Internal methods

    func events() async -> AsyncStream<ConferenceEvent> {
        AsyncStream<ConferenceEvent>(
            bufferingPolicy: .bufferingNewest(1)
        ) { continuation in
            subscribers.append(continuation)
        }
    }

    func open() {
        logger?.info("Subscribing to the event stream")
        skipPresentationStop = true

        eventSourceTask = Task {
            do {
                let events = try await service.events(token: tokenStore.token())

                for try await event in events {
                    reconnectionAttempts = 0
                    handleEvent(event)
                }
            } catch let error as HTTPEventError {
                if let dataStreamError = error.dataStreamError {
                    logger?.warn("Event source disconnected with error: \(dataStreamError)")
                } else if let statusCode = error.response?.statusCode {
                    logger?.warn("Event source connection closed, status code: \(statusCode)")
                } else {
                    logger?.warn("Event source connection unexpectedly closed")
                }

                reconnectionAttempts += 1

                let seconds = min(
                    maxReconnectionTime,
                    reconnectionTime * Double(reconnectionAttempts)
                )

                logger?.info("Waiting \(seconds) seconds before reconnecting...")

                Task {
                    try await Task.sleep(seconds: seconds)

                    if await isOpen {
                        open()
                    } else {
                        reconnectionAttempts = 0
                    }
                }
            }
        }
    }

    func close() async {
        logger?.info("Unsubscribing from the event stream")

        for subscriber in subscribers {
            subscriber.finish()
        }

        subscribers.removeAll()
        eventSourceTask?.cancel()
    }

    // MARK: - Private methods

    private func handleEvent(_ event: Event<ConferenceEvent>) {
        if case .presentationStart = event.data, skipPresentationStop {
            skipPresentationStop = false
            return
        }

        if let reconnectionTime = event.reconnectionTime {
            logger?.debug(
                "Reconnection time is set to \(reconnectionTime)"
            )
            self.reconnectionTime = reconnectionTime
        }

        for subscriber in subscribers {
            subscriber.yield(event.data)
        }
    }
}
