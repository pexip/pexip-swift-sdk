import XCTest
@testable import PexipInfinityClient

final class InfinityEventFactoryTests: APITestCase {
    private let baseURL = URL(string: "https://example.com/api/conference/name/events")!
    private var factory: InfinityEventFactory<ConferenceEventParser>!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        factory = InfinityEventFactory<ConferenceEventParser>(
            url: baseURL,
            client: client,
            parser: ConferenceEventParser()
        )
    }

    // MARK: - Tests

    func testEventStream() async throws {
        // 1. Prepare
        var receivedEvents = [Event<ConferenceEvent>]()
        let token = ConferenceToken.randomToken()
        let expectedEvent = ClientDisconnectEvent(reason: "Test")
        let eventDataString = String(
            data: try JSONEncoder().encode(expectedEvent),
            encoding: .utf8
        ) ?? ""
        let string = """
        id: 1
        data:\(eventDataString)
        event: disconnect


        """
        let data = try XCTUnwrap(string.data(using: .utf8))

        // 2. Mock response
        try setResponse(statusCode: 200, data: data)

        // 2. Receive events from the stream
        do {
            for try await event in await factory.events(token: token) {
                receivedEvents.append(event)
            }
        } catch let error as HTTPEventError {
            XCTAssertEqual(error.response?.url, lastRequest?.url)
            XCTAssertEqual(error.response?.statusCode, 200)
            XCTAssertTrue(error.response?.allHeaderFields.isEmpty == true)
            XCTAssertNil(error.dataStreamError)
        }

        // 3. Assert request
        assertRequest(
            withMethod: .GET,
            url: baseURL,
            token: token,
            data: nil
        )

        // 4. Assert response
        XCTAssertEqual(receivedEvents.count, 1)
        XCTAssertEqual(
            receivedEvents.first,
            Event<ConferenceEvent>(
                id: "1",
                name: "disconnect",
                reconnectionTime: nil,
                data: .clientDisconnected(
                    .init(reason: "Test")
                )
            )
        )
    }
}
