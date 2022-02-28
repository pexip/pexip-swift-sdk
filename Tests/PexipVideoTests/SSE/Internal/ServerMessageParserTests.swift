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
        let expectedMessage = ChatMessage(
            origin: "User",
            uuid: UUID(),
            type: "message",
            payload: "Test"
        )
        let event = try event(for: expectedMessage, name: "message_received")
        let message = parser.message(from: event)

        XCTAssertEqual(message, .chat(expectedMessage))
    }

    func testCallDisconnected() throws {
        let expectedMessage = ServerEvent.CallDisconnected(
            callId: UUID(),
            reason: "Test"
        )
        let event = try event(for: expectedMessage, name: "call_disconnected")
        let message = parser.message(from: event)

        XCTAssertEqual(message, .callDisconnected(expectedMessage))
    }

    func testDisconnect() throws {
        let expectedMessage = ServerEvent.Disconnect(reason: "Test")
        let event = try event(for: expectedMessage, name: "disconnect")
        let message = parser.message(from: event)

        XCTAssertEqual(message, .disconnect(expectedMessage))
    }

    func testUnknown() throws {
        let expectedMessage = ServerEvent.Disconnect(reason: "Test")
        let event = try event(for: expectedMessage, name: "unknown")
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
