import Foundation
import PexipCore

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
    ) async -> AsyncThrowingStream<RegistrationEvent, Error>
}

// MARK: - Implementation

struct DefaultRegistrationEventService: RegistrationEventService {
    let baseURL: URL
    let client: HTTPClient
    var decoder = JSONDecoder()
    var logger: Logger?

    func events(
        token: RegistrationToken
    ) async -> AsyncThrowingStream<RegistrationEvent, Error> {
        let parser = RegistrationEventParser(decoder: decoder, logger: logger)
        var request = URLRequest(
            url: baseURL.appendingPathComponent("events"),
            httpMethod: .GET
        )
        request.setHTTPHeader(.token(token.value))

        return client.eventSource(withRequest: request, transform: {
            parser.parseEventData(from: $0)
        })
    }
}
