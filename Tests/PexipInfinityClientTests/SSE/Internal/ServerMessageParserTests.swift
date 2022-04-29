import XCTest
@testable import PexipInfinityClient

final class ServerMessageParserTests: XCTestCase {
    private var parser: ServerMessageParser!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        parser = ServerMessageParser()
    }

    // MARK: - Tests

    func testEventWithoutName() throws {
        let event = EventSourceEvent(
            id: "1",
            name: nil,
            data: "",
            retry: nil
        )
        XCTAssertNil(parser.message(from: event))
    }

    func testEventWithoutData() throws {
        let event = EventSourceEvent(
            id: "1",
            name: "message_received",
            data: nil,
            retry: nil
        )
        XCTAssertNil(parser.message(from: event))
    }

    func testEventWithInvalidData() throws {
        let event = EventSourceEvent(
            id: "1",
            name: "message_received",
            data: "",
            retry: nil
        )
        XCTAssertNil(parser.message(from: event))
    }

    func testMessageReceived() throws {
        let chatMessage = ChatMessage(
            senderName: "User",
            senderId: UUID(),
            type: "message",
            payload: "Test"
        )
        let event = try event(for: chatMessage, name: "message_received")
        let message = parser.message(from: event)

        switch message {
        case .messageReceived(let message):
            XCTAssertEqual(message.senderName, chatMessage.senderName)
            XCTAssertEqual(message.senderId, chatMessage.senderId)
            XCTAssertEqual(message.type, chatMessage.type)
            XCTAssertEqual(message.payload, chatMessage.payload)
        default:
            XCTFail("Unexpected message type")
        }
    }

    func testPresentationStart() throws {
        let details = PresentationStartMessage(presenterName: "Name", presenterUri: "URI")
        let event = try event(for: details, name: "presentation_start")
        let message = parser.message(from: event)
        XCTAssertEqual(message, .presentationStart(details))
    }

    func testPresentationStop() throws {
        let event = EventSourceEvent(id: "1", name: "presentation_stop")
        let message = parser.message(from: event)
        XCTAssertEqual(message, .presentationStop)
    }

    func testParticipantSyncBegin() throws {
        let event = EventSourceEvent(id: "1", name: "participant_sync_begin")
        let message = parser.message(from: event)
        XCTAssertEqual(message, .participantSyncBegin)
    }

    func testParticipantSyncEnd() throws {
        let event = EventSourceEvent(id: "1", name: "participant_sync_end")
        let message = parser.message(from: event)
        XCTAssertEqual(message, .participantSyncEnd)
    }

    func testParticipantCreate() throws {
        let participant = Participant.stub(withId: UUID(), displayName: "Guest")
        let event = try event(for: participant, name: "participant_create")
        let message = parser.message(from: event)
        XCTAssertEqual(message, .participantCreate(participant))
    }

    func testParticipantUpdate() throws {
        let participant = Participant.stub(withId: UUID(), displayName: "Guest")
        let event = try event(for: participant, name: "participant_update")
        let message = parser.message(from: event)
        XCTAssertEqual(message, .participantUpdate(participant))
    }

    func testParticipantDelete() throws {
        let details = ParticipantDeleteMessage(id: UUID())
        let event = try event(for: details, name: "participant_delete")
        let message = parser.message(from: event)
        XCTAssertEqual(message, .participantDelete(details))
    }

    func testCallDisconnected() throws {
        let details = CallDisconnectMessage(callId: UUID(), reason: "Test")
        let event = try event(for: details, name: "call_disconnected")
        let message = parser.message(from: event)
        XCTAssertEqual(message, .callDisconnected(details))
    }

    func testClientDisconnected() throws {
        let details = ClientDisconnectMessage(reason: "Test")
        let event = try event(for: details, name: "disconnect")
        let message = parser.message(from: event)
        XCTAssertEqual(message, .clientDisconnected(details))
    }

    func testUnknown() throws {
        let event = try event(
            for: ClientDisconnectMessage(reason: "Test"),
            name: "unknown"
        )
        let message = parser.message(from: event)
        XCTAssertNil(message)
    }

    // MARK: - Helper methods

    private func event<T: Encodable>(
        for message: T,
        name: String
    ) throws -> EventSourceEvent {
        return EventSourceEvent(
            id: "1",
            name: name,
            data: String(
                data: try JSONEncoder().encode(message),
                encoding: .utf8
            ) ?? "",
            retry: nil
        )
    }
}
