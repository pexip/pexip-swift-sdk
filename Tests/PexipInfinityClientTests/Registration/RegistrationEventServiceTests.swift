import XCTest
@testable import PexipInfinityClient

final class RegistrationEventServiceTests: APITestCase {
    private let baseURL = URL(string: "https://example.com")!
    private var service: RegistrationEventService!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        service = DefaultRegistrationEventService(baseURL: baseURL, client: client)
    }

    // swiftlint:disable function_body_length
    func testEventStream() async throws {
        // 1. Prepare
        var receivedEvents = [Event<RegistrationEvent>]()
        let token = RegistrationToken.randomToken()
        let expectedEvent = IncomingRegistrationEvent(
            conferenceAlias: "Alias",
            remoteDisplayName: "Name",
            token: UUID().uuidString
        )
        let eventDataString = String(
            data: try JSONEncoder().encode(expectedEvent),
            encoding: .utf8
        ) ?? ""
        let string = """
        id: 1
        data:\(eventDataString)
        event: incoming


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
        XCTAssertEqual(receivedEvents.first?.id, "1")
        XCTAssertEqual(receivedEvents.first?.name, "incoming")
        XCTAssertNil(receivedEvents.first?.reconnectionTime)

        switch receivedEvents.first?.data {
        case .incoming(let incomingEvent):
            XCTAssertEqual(
                incomingEvent.conferenceAlias,
                expectedEvent.conferenceAlias
            )
            XCTAssertEqual(
                incomingEvent.remoteDisplayName,
                expectedEvent.remoteDisplayName
            )
            XCTAssertEqual(incomingEvent.token, expectedEvent.token)
        default:
            XCTFail("Unexpected event type")
        }
    }
}
