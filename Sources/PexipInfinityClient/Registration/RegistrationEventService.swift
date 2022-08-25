import Foundation
import PexipUtils

// MARK: - Protocol

public protocol RegistrationEventService {
    /**
     Creates a new `AsyncThrowingStream` and immediately returns it.
     Creating a steam initiates an asynchronous process to consume server sent
     events from the conference as they occur.

     The caller must break the async for loop or cancel the task when it is
     no longer in use.

     - Parameters:
        - token: Current valid registration token
     - Returns: A new `AsyncThrowingStream` with server sent events
     - Throws: ``HTTPEventError``
     - Throws: ``HTTPError`` if another network error was encountered during operation
     */
    func events(
        token: RegistrationToken
    ) async -> AsyncThrowingStream<Event<RegistrationEvent>, Error>
}

// MARK: - Implementation

struct DefaultRegistrationEventService: RegistrationEventService {
    let baseURL: URL
    let client: HTTPClient
    var decoder = JSONDecoder()
    var logger: Logger?

    func events(
        token: RegistrationToken
    ) async -> AsyncThrowingStream<Event<RegistrationEvent>, Error> {
        let parser = RegistrationEventParser(decoder: decoder, logger: logger)
        return AsyncThrowingStream(
            bufferingPolicy: .bufferingNewest(1)
        ) { continuation in
            let task = Task {
                do {
                    var request = URLRequest(
                        url: baseURL.appendingPathComponent("events"),
                        httpMethod: .GET
                    )
                    request.setHTTPHeader(.token(token.value))

                    let events = client.eventSource(withRequest: request)

                    for try await event in events {
                        if let registrationEvent = parser.registrationEvent(from: event) {
                            continuation.yield(
                                Event(
                                    id: event.id,
                                    name: event.name,
                                    reconnectionTime: event.reconnectionTime,
                                    data: registrationEvent
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
