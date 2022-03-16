import XCTest
@testable import PexipVideo

final class ServerMessageParserTests: APIClientTestCase<ServerEventClientProtocol> {
    private var parser: ServerMessageParser!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        parser = ServerMessageParser(logger: .stub, decoder: JSONDecoder())
    }

    // MARK: - Tests

    func testEventWithoutName() throws {
        let event = EventStreamEvent(
            id: "1",
            name: nil,
            data: "",
            retry: nil
        )
        XCTAssertNil(parser.message(from: event))
    }

    func testEventWithoutData() throws {
        let event = EventStreamEvent(
            id: "1",
            name: "message_received",
            data: nil,
            retry: nil
        )
        XCTAssertNil(parser.message(from: event))
    }

    func testEventWithInvalidData() throws {
        let event = EventStreamEvent(
            id: "1",
            name: "message_received",
            data: "",
            retry: nil
        )
        XCTAssertNil(parser.message(from: event))
    }

    func testChatMessage() throws {
        let chatMessage = ChatMessage(
            senderName: "User",
            senderId: UUID(),
            type: "message",
            payload: "Test"
        )
        let event = try event(for: chatMessage, name: "message_received")
        let message = parser.message(from: event)

        switch message {
        case .chat(let message):
            XCTAssertEqual(message.senderName, chatMessage.senderName)
            XCTAssertEqual(message.senderId, chatMessage.senderId)
            XCTAssertEqual(message.type, chatMessage.type)
            XCTAssertEqual(message.payload, chatMessage.payload)
        default:
            XCTFail("Unexpected message type")
        }
    }

    func testPresentationStarted() throws {
        let details = PresentationDetails(presenterName: "Name", presenterUri: "URI")
        let event = try event(for: details, name: "presentation_start")
        let message = parser.message(from: event)
        XCTAssertEqual(message, .presentationStarted(details))
    }

    func testPresentationStopped() throws {
        let event = EventStreamEvent(id: "1", name: "presentation_stop")
        let message = parser.message(from: event)
        XCTAssertEqual(message, .presentationStopped)
    }

    func testParticipantSyncBegan() throws {
        let event = EventStreamEvent(id: "1", name: "participant_sync_begin")
        let message = parser.message(from: event)
        XCTAssertEqual(message, .participantSyncBegan)
    }

    func testParticipantSyncEnded() throws {
        let event = EventStreamEvent(id: "1", name: "participant_sync_end")
        let message = parser.message(from: event)
        XCTAssertEqual(message, .participantSyncEnded)
    }

    func testParticipantCreated() throws {
        let participant = Participant.stub(withId: UUID(), displayName: "Guest")
        let event = try event(for: participant, name: "participant_create")
        let message = parser.message(from: event)
        XCTAssertEqual(message, .participantCreated(participant))
    }

    func testParticipantUpdated() throws {
        let participant = Participant.stub(withId: UUID(), displayName: "Guest")
        let event = try event(for: participant, name: "participant_update")
        let message = parser.message(from: event)
        XCTAssertEqual(message, .participantUpdated(participant))
    }

    func testParticipantDeleted() throws {
        let details = ParticipantDeleteDetails(uuid: UUID())
        let event = try event(for: details, name: "participant_delete")
        let message = parser.message(from: event)
        XCTAssertEqual(message, .participantDeleted(details))
    }

    func testCallDisconnected() throws {
        let details = CallDisconnectDetails(callId: UUID(), reason: "Test")
        let event = try event(for: details, name: "call_disconnected")
        let message = parser.message(from: event)
        XCTAssertEqual(message, .callDisconnected(details))
    }

    func testClientDisconnected() throws {
        let details = ClientDisconnectDetails(reason: "Test")
        let event = try event(for: details, name: "disconnect")
        let message = parser.message(from: event)
        XCTAssertEqual(message, .clientDisconnected(details))
    }

    func testUnknown() throws {
        let event = try event(
            for: ClientDisconnectDetails(reason: "Test"),
            name: "unknown"
        )
        let message = parser.message(from: event)
        XCTAssertNil(message)
    }

    // MARK: - Helper methods

    private func event<T: Encodable>(
        for message: T,
        name: String
    ) throws -> EventStreamEvent {
        return EventStreamEvent(
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
