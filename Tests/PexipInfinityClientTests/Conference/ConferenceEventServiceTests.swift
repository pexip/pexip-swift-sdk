import XCTest
@testable import PexipInfinityClient

final class ConferenceEventServiceTests: APITestCase {
    private let baseURL = URL(string: "https://example.com")!
    private var service: ConferenceEventService!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        service = DefaultConferenceEventService(baseURL: baseURL, client: client)
    }

    func testEventStream() async throws {
        // 1. Prepare
        var receivedEvents = [Event<ConferenceEvent>]()
        let token = Token.randomToken()
        let message = ClientDisconnectMessage(reason: "Test")
        let messageDataString = String(
            data: try JSONEncoder().encode(message),
            encoding: .utf8
        ) ?? ""
        let string = """
        id: 1
        data:\(messageDataString)
        event: disconnect


        """
        let data = try XCTUnwrap(string.data(using: .utf8))

        // 2. Mock response
        try setResponse(statusCode: 200, data: data)

        // 2. Receive events from the stream
        do {
            for try await event in await service.events(token: token) {
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
            url: baseURL.appendingPathComponent("events"),
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
