import XCTest
import Combine
@testable import PexipInfinityClient

final class ChatMessageTests: XCTestCase {
    private let senderName = "Test"
    private let senderId = UUID().uuidString
    private let payload = "Text message"

    // MARK: - Tests

    func testInit() throws {
        let bodyType = "text/plain"
        let message = ChatMessage(
            senderName: senderName,
            senderId: senderId,
            type: bodyType,
            payload: payload
        )

        XCTAssertEqual(message.senderName, senderName)
        XCTAssertEqual(message.senderId, senderId)
        XCTAssertEqual(message.type, bodyType)
        XCTAssertEqual(message.payload, payload)
    }

    func testInitWithDefaultType() throws {
        let message = ChatMessage(
            senderName: senderName,
            senderId: senderId,
            payload: payload
        )

        XCTAssertEqual(message.senderName, senderName)
        XCTAssertEqual(message.type, "text/plain")
    }
}
