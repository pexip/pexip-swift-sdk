import XCTest
@testable import PexipInfinityClient

final class EventSourceEventTests: XCTestCase {
    func testReconnectionTime() {
        let event = EventSourceEvent(
            id: nil,
            name: "message",
            data: nil,
            retry: "1000"
        )

        XCTAssertEqual(event.reconnectionTime, 1)
    }

    func testReconnectionTimeWithInvalidRetryField() {
        let event = EventSourceEvent(
            id: nil,
            name: "message",
            data: nil,
            retry: "string"
        )

        XCTAssertNil(event.reconnectionTime)
    }
}
