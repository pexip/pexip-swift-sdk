import Foundation
import PexipUtils

struct InfinityEventFactory<Parser: InfinityEventParser> {
    let url: URL
    let client: HTTPClient
    let parser: Parser

    func events(
        token: InfinityToken
    ) async -> AsyncThrowingStream<Event<Parser.OutputEvent>, Error> {
        return AsyncThrowingStream(
            bufferingPolicy: .bufferingNewest(1)
        ) { continuation in
            let task = Task {
                do {
                    var request = URLRequest(url: url, httpMethod: .GET)
                    request.setHTTPHeader(.token(token.value))

                    let events = client.eventSource(withRequest: request)

                    for try await event in events {
                        if let data = parser.parseEventData(from: event) {
                            continuation.yield(
                                Event(
                                    id: event.id,
                                    name: event.name,
                                    reconnectionTime: event.reconnectionTime,
                                    data: data
                                )
                            )
                        }
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
