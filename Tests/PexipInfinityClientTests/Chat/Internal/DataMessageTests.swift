import XCTest
import Combine
@testable import PexipInfinityClient

final class DataMessageTests: XCTestCase {
    private let senderName = "Test"
    private let senderId = UUID().uuidString
    private let bodyType = "text/plain"
    private let payload = "Text message"

    // MARK: - Tests

    func testDecoding() throws {
        let json = """
        {
            "type": "message",
            "body": {
                "origin": "\(senderName)",
                "uuid": "\(senderId)",
                "type": "\(bodyType)",
                "payload": "\(payload)"
            }
        }
        """

        let data = try XCTUnwrap(json.data(using: .utf8))
        let dataMessage = try JSONDecoder().decode(
            DataMessage.self,
            from: data
        )

        switch dataMessage {
        case .text(let message):
            XCTAssertEqual(message.senderName, senderName)
            XCTAssertEqual(message.senderId, senderId)
            XCTAssertEqual(message.type, bodyType)
            XCTAssertEqual(message.payload, payload)
        }
    }

    func testEncoding() throws {
        let message = ChatMessage(
            senderName: senderName,
            senderId: senderId,
            type: bodyType,
            payload: payload
        )
        let dataMessage = DataMessage.text(message)
        let data = try JSONEncoder().encode(dataMessage)
        let decodedDataMessage = try JSONDecoder().decode(
            DataMessage.self,
            from: data
        )

        switch decodedDataMessage {
        case .text(let decodedMessage):
            XCTAssertEqual(decodedMessage.senderName, message.senderName)
            XCTAssertEqual(decodedMessage.senderId, message.senderId)
            XCTAssertEqual(decodedMessage.type, message.type)
            XCTAssertEqual(decodedMessage.payload, message.payload)
        }
    }
}
