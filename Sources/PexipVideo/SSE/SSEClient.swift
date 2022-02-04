import Foundation

// MARK: - Protocol

/// Pexip client REST API v2.
protocol SSEClientProtocol {
    func eventStream() async -> AsyncStream<ConferenceEvent>
    func connect() async throws
    func disconnect() async
}

// MARK: - Implementation

actor SSEClient: SSEClientProtocol {
    private let decoder = JSONDecoder()
    private let urlProtocolClasses: [AnyClass]
    private let logger: CategoryLogger
    private let requestFactory: HTTPRequestFactory
    private let maxReconnectionTime: TimeInterval = 10
    private var reconnectionTime: TimeInterval = 3
    private var reconnectionAttempts: Int = 0
    private var lastEventId: String?
    private var eventSourceTask: Task<Void, Error>?
    private var subscribers = [AsyncStream<ConferenceEvent>.Continuation]()

    // MARK: - Init

    init(
        apiConfiguration: APIConfiguration,
        authStorage: AuthStorage,
        logger: CategoryLogger,
        urlProtocolClasses: [AnyClass] = []
    ) {
        self.urlProtocolClasses = urlProtocolClasses
        self.logger = logger
        self.requestFactory = HTTPRequestFactory(
            baseURL: apiConfiguration.conferenceBaseURL,
            authTokenProvider: authStorage
        )
    }

    // MARK: - Internal methods

    func connect() async throws {
        let request = try await requestFactory.request(withName: "events", method: .GET)
        logger.info("Subscribing to the event stream from \(request.url?.absoluteString ?? "?")")

        eventSourceTask = Task {
            do {
                let stream = EventSource.eventStream(
                    withRequest: request,
                    lastEventId: lastEventId,
                    urlProtocolClasses: urlProtocolClasses
                )

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
                    try await connect()
                }
            }
        }
    }

    func disconnect() async {
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
            print()
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
