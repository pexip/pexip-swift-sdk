import XCTest
@testable import PexipInfinityClient

final class ServerEventServiceTests: XCTestCase {
    private let baseURL = URL(string: "https://example.com")!
    private var service: ServerEventService!

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolMock.self]

        service = DefaultServerEventService(
            baseURL: baseURL,
            client: HTTPClient(session: URLSession(configuration: configuration))
        )
    }

    // swiftlint:disable function_body_length
    func testEventStream() async throws {
        // 1. Prepare
        var createdRequest: URLRequest?
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
        URLProtocolMock.makeResponse = { request in
            createdRequest = request
            return .http(statusCode: 200, data: data, headers: nil)
        }

        // 2. Receive events from the stream
        do {
            for try await event in await service.serverSentEvents(token: token) {
                receivedEvents.append(event)
            }
        } catch let error as EventSourceError {
            XCTAssertEqual(error.response?.url, createdRequest?.url)
            XCTAssertEqual(error.response?.statusCode, 200)
            XCTAssertTrue(error.response?.allHeaderFields.isEmpty == true)
            XCTAssertNil(error.dataStreamError)
        }

        // 3. Assert request
        let expectedURL = baseURL.appendingPathComponent("events")
        XCTAssertEqual(createdRequest?.url, expectedURL)
        XCTAssertEqual(createdRequest?.httpMethod, "GET")
        XCTAssertEqual(
            createdRequest?.value(forHTTPHeaderField: "User-Agent"),
            HTTPHeader.defaultUserAgent.value
        )
        XCTAssertEqual(
            createdRequest?.value(forHTTPHeaderField: "token"),
            token.value
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
