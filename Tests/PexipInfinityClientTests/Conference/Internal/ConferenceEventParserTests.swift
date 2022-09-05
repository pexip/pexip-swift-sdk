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

    func testConferenceUpdate() throws {
        let expectedStatus = ConferenceStatus(
            started: true,
            locked: false,
            allMuted: false,
            guestsMuted: false,
            presentationAllowed: true,
            directMedia: false,
            liveCaptionsAvailable: true
        )
        let httpEvent = try HTTPEvent.stub(for: expectedStatus, name: "conference_update")

        switch parser.parseEventData(from: httpEvent) {
        case .conferenceUpdate(let status):
            XCTAssertEqual(status.started, expectedStatus.started)
            XCTAssertEqual(status.locked, expectedStatus.locked)
            XCTAssertEqual(status.allMuted, expectedStatus.allMuted)
            XCTAssertEqual(status.guestsMuted, expectedStatus.guestsMuted)
            XCTAssertEqual(
                status.presentationAllowed,
                expectedStatus.presentationAllowed
            )
            XCTAssertEqual(status.directMedia, expectedStatus.directMedia)
            XCTAssertEqual(
                status.liveCaptionsAvailable,
                expectedStatus.liveCaptionsAvailable
            )
        default:
            XCTFail("Unexpected event type")
        }
    }

    func testMessageReceived() throws {
        let chatMessage = ChatMessage(
            senderName: "User",
            senderId: UUID(),
            type: "message",
            payload: "Test"
        )
        let httpEvent = try HTTPEvent.stub(for: chatMessage, name: "message_received")

        switch parser.parseEventData(from: httpEvent) {
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

        switch parser.parseEventData(from: httpEvent) {
        case .presentationStart(let event):
            XCTAssertEqual(event.presenterName, expectedEvent.presenterName)
            XCTAssertEqual(event.presenterUri, expectedEvent.presenterUri)
        default:
            XCTFail("Invalid event type")
        }
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

        switch parser.parseEventData(from: httpEvent) {
        case .participantDelete(let event):
            XCTAssertEqual(event.id, expectedEvent.id)
        default:
            XCTFail("Invalid event type")
        }
    }

    func testCallDisconnected() throws {
        let expectedEvent = CallDisconnectEvent(callId: UUID(), reason: "Test")
        let httpEvent = try HTTPEvent.stub(for: expectedEvent, name: "call_disconnected")

        switch parser.parseEventData(from: httpEvent) {
        case .callDisconnected(let event):
            XCTAssertEqual(event.callId, expectedEvent.callId)
            XCTAssertEqual(event.reason, expectedEvent.reason)
        default:
            XCTFail("Invalid event type")
        }
    }

    func testClientDisconnected() throws {
        let expectedEvent = ClientDisconnectEvent(reason: "Test")
        let httpEvent = try HTTPEvent.stub(for: expectedEvent, name: "disconnect")

        switch parser.parseEventData(from: httpEvent) {
        case .clientDisconnected(let event):
            XCTAssertEqual(event.reason, expectedEvent.reason)
        default:
            XCTFail("Invalid event type")
        }
    }

    func testLiveCaptions() throws {
        let expectedLiveCaptions = LiveCaptions(
            data: "Test",
            isFinal: true,
            sentAt: Date().timeIntervalSinceReferenceDate,
            receivedAt: Date().timeIntervalSinceReferenceDate
        )
        let httpEvent = try HTTPEvent.stub(for: expectedLiveCaptions, name: "live_captions")

        switch parser.parseEventData(from: httpEvent) {
        case .liveCaptions(let liveCaptions):
            XCTAssertEqual(liveCaptions, expectedLiveCaptions)
        default:
            XCTFail("Unexpected event type")
        }
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
