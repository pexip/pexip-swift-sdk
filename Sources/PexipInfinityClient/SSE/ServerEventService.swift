import Foundation
import PexipUtils

// MARK: - Protocol

public protocol ServerEventService {
    func serverSentEvents(token: Token) async -> AsyncThrowingStream<ServerEvent, Error>
}

// MARK: - Implementation

struct DefaultServerEventService: ServerEventService {
    let baseURL: URL
    let client: HTTPClient
    var decoder = JSONDecoder()
    var logger: Logger?

    func serverSentEvents(token: Token) async -> AsyncThrowingStream<ServerEvent, Error> {
        let parser = ServerMessageParser(decoder: decoder, logger: logger)
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    var request = URLRequest(
                        url: baseURL.appendingPathComponent("events"),
                        httpMethod: .GET
                    )
                    request.setHTTPHeader(.token(token.value))

                    let events = client.eventSource(withRequest: request)

                    for try await event in events {
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
