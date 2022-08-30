import Foundation
import PexipUtils

// MARK: - Protocol

public protocol ConferenceEventService {
    /**
     Creates a new `AsyncThrowingStream` and immediately returns it.
     Creating a steam initiates an asynchronous process to consume server sent
     events from the conference as they occur.

     See [documentation](https://docs.pexip.com/api_client/api_rest.htm?Highlight=api#server_sent).

     The caller must break the async for loop or cancel the task when it is
     no longer in use.

     - Parameters:
        - token: Current valid API token
     - Returns: A new `AsyncThrowingStream` with server sent events
     - Throws: ``HTTPEventError``
     - Throws: ``HTTPError`` if another network error was encountered during operation
     */
    func events(token: ConferenceToken) async -> AsyncThrowingStream<ConferenceEvent, Error>
}

// MARK: - Implementation

struct DefaultConferenceEventService: ConferenceEventService {
    let baseURL: URL
    let client: HTTPClient
    var decoder = JSONDecoder()
    var logger: Logger?

    func events(
        token: ConferenceToken
    ) async -> AsyncThrowingStream<ConferenceEvent, Error> {
        let parser = ConferenceEventParser(decoder: decoder, logger: logger)
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
