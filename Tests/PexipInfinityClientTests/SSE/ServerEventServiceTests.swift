import XCTest
@testable import PexipInfinityClient

final class ServerEventServiceTests: APITestCase {
    private let baseURL = URL(string: "https://example.com")!
    private var service: ServerEventService!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        service = DefaultServerEventService(baseURL: baseURL, client: client)
    }

    // swiftlint:disable function_body_length
    func testEventStream() async throws {
        // 1. Prepare
        var receivedEvents = [ServerEvent]()
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
            for try await event in await service.serverSentEvents(token: token) {
                receivedEvents.append(event)
            }
        } catch let error as EventSourceError {
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
            ServerEvent(
                rawEvent: .init(
                    id: "1",
                    name: "disconnect",
                    data: "\(messageDataString)",
                    retry: nil
                ),
                message: .clientDisconnected(
                    .init(reason: "Test")
                )
            )
        )
    }
}
