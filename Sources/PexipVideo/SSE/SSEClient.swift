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
    private let requestFactory: HTTPRequestFactory
    private var reconnectionTime: TimeInterval = 3
    private var lastEventId: String?
    private var eventSourceTask: Task<Void, Error>?
    private var subscribers = [AsyncStream<ConferenceEvent>.Continuation]()

    // MARK: - Init

    init(
        apiConfiguration: APIConfiguration,
        authStorage: AuthStorage,
        urlProtocolClasses: [AnyClass] = []
    ) {
        self.urlProtocolClasses = urlProtocolClasses
        self.requestFactory = HTTPRequestFactory(
            baseURL: apiConfiguration.conferenceBaseURL,
            authTokenProvider: authStorage
        )
    }

    // MARK: - Internal methods

    func connect() async throws {
        eventSourceTask = Task {
            do {
                let stream = try await makeEventSourceStream()

                for try await event in stream {
                    lastEventId = event.id

                    if let reconnectionTime = event.reconnectionTime {
                        self.reconnectionTime = reconnectionTime
                    }

                    if let conferenceEvent = conferenceEvent(from: event) {
                        for subscriber in subscribers {
                            subscriber.yield(conferenceEvent)
                        }
                    }
                }
            } catch let error as EventSourceError {
                print(error)
            }
        }
    }

    func disconnect() async {
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

    private func makeEventSourceStream() async throws -> AsyncThrowingStream<MessageEvent, Error> {
        EventSource.eventStream(
            withRequest: try await requestFactory.request(
                withName: "events",
                method: .GET
            ),
            lastEventId: lastEventId,
            urlProtocolClasses: urlProtocolClasses
        )
    }

    private func conferenceEvent(from event: MessageEvent) -> ConferenceEvent? {
        guard let name = event.name else {
            return nil
        }

        let data = event.data?.data(using: .utf8)

        do {
            switch name {
            case "message_received":
                return .chatMessage(try decoder.decode(ChatMessage.self, from: data))
            default:
                print("SSE event: '\(name)' was not handled")
                return nil
            }
        } catch {
            print("Failed to decode SSE event: `\(name)`, error: \(error)")
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
