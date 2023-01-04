import XCTest
@testable import PexipInfinityClient

final class RegistrationEventParserTests: XCTestCase {
    private var parser: RegistrationEventParser!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        parser = RegistrationEventParser()
    }

    // MARK: - Tests

    func testParseEventDataWithoutName() throws {
        let event = HTTPEvent(
            id: nil,
            name: nil,
            data: "",
            retry: nil
        )
        XCTAssertNil(parser.parseEventData(from: event))
    }

    func testParseEventDataWithoutData() throws {
        let event = HTTPEvent(
            id: "1",
            name: "incoming",
            data: nil,
            retry: nil
        )
        XCTAssertNil(parser.parseEventData(from: event))
    }

    func testParseEventDataWithInvalidData() throws {
        let event = HTTPEvent(
            id: "1",
            name: "incoming",
            data: "",
            retry: nil
        )
        XCTAssertNil(parser.parseEventData(from: event))
    }

    func testIncoming() throws {
        let expectedEvent = IncomingCallEvent(
            conferenceAlias: "Alias",
            remoteDisplayName: "Name",
            token: UUID().uuidString
        )
        let httpEvent = try HTTPEvent.stub(for: expectedEvent, name: "incoming")
        let parsedEvent = parser.parseEventData(from: httpEvent)

        switch parsedEvent {
        case .incoming(let event):
            XCTAssertEqual(event, expectedEvent)
        default:
            XCTFail("Unexpected event type")
        }
    }

    func testIncomingCancelled() throws {
        let expectedEvent = IncomingCallCancelledEvent(
            token: UUID().uuidString
        )
        let httpEvent = try HTTPEvent.stub(for: expectedEvent, name: "incoming_cancelled")
        let parsedEvent = parser.parseEventData(from: httpEvent)

        switch parsedEvent {
        case .incomingCancelled(let event):
            XCTAssertEqual(event, expectedEvent)
        default:
            XCTFail("Unexpected event type")
        }
    }

    func testUnknown() throws {
        let httpEvent = try HTTPEvent.stub(
            for: IncomingCallCancelledEvent(token: UUID().uuidString),
            name: "unknown"
        )
        let event = parser.parseEventData(from: httpEvent)
        XCTAssertNil(event)
    }

    func testOptionalStringDebug() {
        XCTAssertEqual(("Test" as String?).debug, "Test")
        XCTAssertEqual(String?.none.debug, "none")
    }
}
