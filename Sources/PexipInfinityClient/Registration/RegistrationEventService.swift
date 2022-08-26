import Foundation
import PexipUtils

// MARK: - Protocol

public protocol RegistrationEventService {
    /**
     Creates a new `AsyncThrowingStream` and immediately returns it.
     Creating a steam initiates an asynchronous process to consume server sent
     events as they occur.

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
        await InfinityEventFactory(
            url: baseURL.appendingPathComponent("events"),
            client: client,
            parser: RegistrationEventParser(decoder: decoder, logger: logger)
        ).events(token: token)
    }
}
