import XCTest
@testable import PexipInfinityClient

final class HTTPEventTests: XCTestCase {
    func testReconnectionTime() {
        let event = HTTPEvent(
            id: nil,
            name: "message",
            data: nil,
            retry: "1000"
        )

        XCTAssertEqual(event.reconnectionTime, 1)
    }

    func testReconnectionTimeWithInvalidRetryField() {
        let event = HTTPEvent(
            id: nil,
            name: "message",
            data: nil,
            retry: "string"
        )

        XCTAssertNil(event.reconnectionTime)
    }
}
