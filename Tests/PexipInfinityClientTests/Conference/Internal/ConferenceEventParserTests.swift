import XCTest
@testable import PexipInfinityClient

final class ConferenceEventParserTests: XCTestCase {
    private var parser: ConferenceEventParser!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        parser = ConferenceEventParser()
    }

    // MARK: - Tests

    func testParseEventDataWithoutName() throws {
        let event = HTTPEvent(
            id: "1",
            name: nil,
            data: "",
            retry: nil
        )
        XCTAssertNil(parser.parseEventData(from: event))
    }

    func testParseEventDataWithoutData() throws {
        let event = HTTPEvent(
            id: "1",
            name: "message_received",
            data: nil,
            retry: nil
        )
        XCTAssertNil(parser.parseEventData(from: event))
    }

    func testParseEventDataWithInvalidData() throws {
        let event = HTTPEvent(
            id: "1",
            name: "message_received",
            data: "",
            retry: nil
        )
        XCTAssertNil(parser.parseEventData(from: event))
    }

    func testMessageReceived() throws {
        let chatMessage = ChatMessage(
            senderName: "User",
            senderId: UUID(),
            type: "message",
            payload: "Test"
        )
        let httpEvent = try HTTPEvent.stub(for: chatMessage, name: "message_received")
        let event = parser.parseEventData(from: httpEvent)

        switch event {
        case .messageReceived(let message):
            XCTAssertEqual(message.senderName, chatMessage.senderName)
            XCTAssertEqual(message.senderId, chatMessage.senderId)
            XCTAssertEqual(message.type, chatMessage.type)
            XCTAssertEqual(message.payload, chatMessage.payload)
        default:
            XCTFail("Unexpected event type")
        }
    }

    func testPresentationStart() throws {
        let expectedEvent = PresentationStartEvent(
            presenterName: "Name",
            presenterUri: "URI"
        )
        let httpEvent = try HTTPEvent.stub(for: expectedEvent, name: "presentation_start")
        let parsedEvent = parser.parseEventData(from: httpEvent)
        XCTAssertEqual(parsedEvent, .presentationStart(expectedEvent))
    }

    func testPresentationStop() throws {
        let httpEvent = HTTPEvent(id: "1", name: "presentation_stop")
        let event = parser.parseEventData(from: httpEvent)
        XCTAssertEqual(event, .presentationStop)
    }

    func testParticipantSyncBegin() throws {
        let httpEvent = HTTPEvent(id: "1", name: "participant_sync_begin")
        let event = parser.parseEventData(from: httpEvent)
        XCTAssertEqual(event, .participantSyncBegin)
    }

    func testParticipantSyncEnd() throws {
        let httpEvent = HTTPEvent(id: "1", name: "participant_sync_end")
        let event = parser.parseEventData(from: httpEvent)
        XCTAssertEqual(event, .participantSyncEnd)
    }

    func testParticipantCreate() throws {
        let participant = Participant.stub(withId: UUID(), displayName: "Guest")
        let httpEvent = try HTTPEvent.stub(for: participant, name: "participant_create")
        let event = parser.parseEventData(from: httpEvent)
        XCTAssertEqual(event, .participantCreate(participant))
    }

    func testParticipantUpdate() throws {
        let participant = Participant.stub(withId: UUID(), displayName: "Guest")
        let httpEvent = try HTTPEvent.stub(for: participant, name: "participant_update")
        let event = parser.parseEventData(from: httpEvent)
        XCTAssertEqual(event, .participantUpdate(participant))
    }

    func testParticipantDelete() throws {
        let expectedEvent = ParticipantDeleteEvent(id: UUID())
        let httpEvent = try HTTPEvent.stub(for: expectedEvent, name: "participant_delete")
        let parsedEvent = parser.parseEventData(from: httpEvent)
        XCTAssertEqual(parsedEvent, .participantDelete(expectedEvent))
    }

    func testCallDisconnected() throws {
        let expectedEvent = CallDisconnectEvent(callId: UUID(), reason: "Test")
        let httpEvent = try HTTPEvent.stub(for: expectedEvent, name: "call_disconnected")
        let parsedEvent = parser.parseEventData(from: httpEvent)
        XCTAssertEqual(parsedEvent, .callDisconnected(expectedEvent))
    }

    func testClientDisconnected() throws {
        let expectedEvent = ClientDisconnectEvent(reason: "Test")
        let httpEvent = try HTTPEvent.stub(for: expectedEvent, name: "disconnect")
        let parsedEvent = parser.parseEventData(from: httpEvent)
        XCTAssertEqual(parsedEvent, .clientDisconnected(expectedEvent))
    }

    func testUnknown() throws {
        let httpEvent = try HTTPEvent.stub(
            for: ClientDisconnectEvent(reason: "Test"),
            name: "unknown"
        )
        let event = parser.parseEventData(from: httpEvent)
        XCTAssertNil(event)
    }
}
