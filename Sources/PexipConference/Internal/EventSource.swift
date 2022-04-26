import Foundation
import PexipInfinityClient
import PexipUtils

// MARK: - Protocol

protocol EventSource {
    func messages() async -> AsyncStream<ServerEvent.Message>
    func open() async
    func close() async
}

// MARK: - Implementation

actor DefaultEventSource: EventSource {
    private let decoder = JSONDecoder()
    private let service: ServerEventService
    private let tokenStore: TokenStore
    private let logger: Logger?
    private let maxReconnectionTime: TimeInterval = 10
    private var reconnectionTime: TimeInterval = 3
    private var reconnectionAttempts: Int = 0
    private var lastEventId: String?
    private var eventSourceTask: Task<Void, Error>?
    private var subscribers = [AsyncStream<ServerEvent.Message>.Continuation]()

    // MARK: - Init

    init(service: ServerEventService, tokenStore: TokenStore, logger: Logger? = nil) {
        self.service = service
        self.tokenStore = tokenStore
        self.logger = logger
    }

    // MARK: - Internal methods

    func messages() async -> AsyncStream<ServerEvent.Message> {
        AsyncStream<ServerEvent.Message> { continuation in
            subscribers.append(continuation)
        }
    }

    func open() async {
        logger?.info("Subscribing to the event stream")

        eventSourceTask = Task {
            do {
                let events = try await service.serverSentEvents(token: tokenStore.token())

                for try await event in events {
                    reconnectionAttempts = 0
                    handleEvent(event)
                }
            } catch let error as EventSourceError {
                if let dataStreamError = error.dataStreamError {
                    logger?.warn("Event source disconnected with error: \(dataStreamError)")
                } else if let statusCode = error.response?.statusCode {
                    logger?.warn("Event source connection closed, status code: \(statusCode)")
                } else {
                    logger?.warn("Event source connection unexpectedly closed")
                }

                let maxSeconds = min(
                    maxReconnectionTime,
                    reconnectionTime * pow(2.0, Double(reconnectionAttempts))
                )
                let seconds = maxSeconds / 2 + Double.random(in: 0...(maxSeconds / 2))

                logger?.info("Waiting \(seconds) seconds before reconnecting...")

                Task {
                    try await Task.sleep(seconds: seconds)

                    if eventSourceTask?.isCancelled == false {
                        reconnectionAttempts += 1
                        await open()
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

    private func handleEvent(_ event: ServerEvent) {
        logger?.debug(
            "Got an event with ID: \(event.id ?? "None"), name: \(event.name ?? "None")"
        )

        lastEventId = event.id

        if let reconnectionTime = event.reconnectionTime {
            logger?.debug(
                "Reconnection time is set to \(reconnectionTime)"
            )
            self.reconnectionTime = reconnectionTime
        }

        if let message = event.message {
            for subscriber in subscribers {
                subscriber.yield(message)
            }
        }
    }
}
