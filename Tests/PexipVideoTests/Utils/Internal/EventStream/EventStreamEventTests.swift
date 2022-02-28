import XCTest
@testable import PexipVideo

final class EventStreamEventTests: XCTestCase {
    func testReconnectionTime() {
        let event = EventStreamEvent(
            id: nil,
            name: "message",
            data: nil,
            retry: "1000"
        )

        XCTAssertEqual(event.reconnectionTime, 1)
    }

    func testReconnectionTimeWithInvalidRetryField() {
        let event = EventStreamEvent(
            id: nil,
            name: "message",
            data: nil,
            retry: "string"
        )

        XCTAssertNil(event.reconnectionTime)
    }
}
