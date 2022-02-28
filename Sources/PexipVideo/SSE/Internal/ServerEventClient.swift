import Foundation

// MARK: - Protocol

/// Pexip client REST API v2.
protocol ServerEventClientProtocol {
    func eventStream(
        lastEventId: String?
    ) async throws -> AsyncThrowingStream<ServerEvent, Error>
}

// MARK: - Implementation

extension InfinityClient: ServerEventClientProtocol {
    func eventStream(
        lastEventId: String?
    ) async throws -> AsyncThrowingStream<ServerEvent, Error> {
        let parser = ServerMessageParser(
            logger: logger[.sse],
            decoder: decoder
        )
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let stream = eventStream(
                        withRequest: try await request(
                            withMethod: .GET,
                            path: .conference,
                            name: "events"
                        ),
                        lastEventId: lastEventId
                    )

                    for try await event in stream {
                        continuation.yield(
                            ServerEvent(
                                rawEvent: event,
                                message: parser.message(from: event)
                            )
                        )
                    }
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }
}
