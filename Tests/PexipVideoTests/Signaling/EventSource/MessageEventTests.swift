import XCTest
@testable import PexipVideo

final class MessageEventTests: XCTestCase {
    func testReconnectionTime() {
        let event = MessageEvent(
            id: nil,
            name: "message",
            data: nil,
            retry: "1000"
        )

        XCTAssertEqual(event.reconnectionTime, 1)
    }

    func testReconnectionTimeWithInvalidRetryField() {
        let event = MessageEvent(
            id: nil,
            name: "message",
            data: nil,
            retry: "string"
        )

        XCTAssertNil(event.reconnectionTime)
    }
}
