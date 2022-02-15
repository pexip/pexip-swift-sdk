import Foundation

// MARK: - Protocol

protocol ConferenceEventSourceProtocol {
    func open() async throws
    func close() async
    func eventStream() async -> AsyncStream<ConferenceEvent>
}

// MARK: - Implementation

actor ConferenceEventSource: ConferenceEventSourceProtocol {
    private let decoder = JSONDecoder()
    private let client: ConferenceEventClientProtocol
    private let logger: CategoryLogger
    private let maxReconnectionTime: TimeInterval = 10
    private var reconnectionTime: TimeInterval = 3
    private var reconnectionAttempts: Int = 0
    private var lastEventId: String?
    private var eventSourceTask: Task<Void, Error>?
    private var subscribers = [AsyncStream<ConferenceEvent>.Continuation]()

    // MARK: - Init

    init(client: ConferenceEventClientProtocol, logger: LoggerProtocol) {
        self.client = client
        self.logger = logger[.sse]
    }

    // MARK: - Internal methods

    func open() async throws {
        logger.info("Subscribing to the event stream")

        eventSourceTask = Task {
            do {
                let stream = try await client.eventStream(lastEventId: lastEventId)

                for try await event in stream {
                    reconnectionAttempts = 0
                    handleEvent(event)
                }
            } catch let error as EventSourceError {
                if let dataStreamError = error.dataStreamError {
                    logger.warn("Event source disconnected with error: \(dataStreamError)")
                } else if let statusCode = error.response?.statusCode {
                    logger.warn("Event source connection closed, status code: \(statusCode)")
                } else {
                    logger.warn("Event source connection unexpectedly closed")
                }

                let maxSeconds = min(
                    maxReconnectionTime,
                    reconnectionTime * pow(2.0, Double(reconnectionAttempts))
                )
                let seconds = maxSeconds / 2 + Double.random(in: 0...(maxSeconds / 2))

                logger.info("Waiting \(seconds) seconds before reconnecting...")

                Task {
                    try await Task.sleep(seconds: seconds)
                    reconnectionAttempts += 1
                    try await open()
                }
            }
        }
    }

    func close() async {
        logger.info("Unsubscribing from the event stream")

        for subscriber in subscribers {
            subscriber.finish()
        }

        subscribers.removeAll()
        eventSourceTask?.cancel()
    }

    func eventStream() async -> AsyncStream<ConferenceEvent> {
        AsyncStream<ConferenceEvent> { continuation in
            subscribers.append(continuation)
        }
    }

    // MARK: - Private methods

    private func handleEvent(_ event: MessageEvent) {
        logger.debug(
            "Got an event with ID: \(event.id ?? "None"), name: \(event.name ?? "None")"
        )

        lastEventId = event.id

        if let reconnectionTime = event.reconnectionTime {
            logger.debug(
                "Reconnection time is set to \(reconnectionTime)"
            )
            self.reconnectionTime = reconnectionTime
        }

        if let conferenceEvent = conferenceEvent(from: event) {
            for subscriber in subscribers {
                subscriber.yield(conferenceEvent)
            }
        }
    }

    private func conferenceEvent(from event: MessageEvent) -> ConferenceEvent? {
        guard let name = event.name else {
            logger.debug("Received event without a name")
            return nil
        }

        let data = event.data?.data(using: .utf8)

        do {
            switch name {
            case "message_received":
                return .chatMessage(try decoder.decode(ChatMessage.self, from: data))
            default:
                logger.debug("SSE event: '\(name)' was not handled")
                return nil
            }
        } catch {
            logger.error("Failed to decode SSE event: '\(name)', error: \(error)")
            return nil
        }
    }
}

// MARK: - Private extensions

private extension JSONDecoder {
    func decode<T>(_ type: T.Type, from data: Data?) throws -> T where T: Decodable {
        try decode(type, from: data.orThrow(HTTPError.noDataInResponse))
    }
}
