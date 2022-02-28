import XCTest
@testable import PexipVideo

final class ServerEventTests: XCTestCase {
    func testDynamicMemberLookup() {
        let rawEvent = EventStreamEvent(
            id: "1",
            name: "name",
            data: "data",
            retry: "120"
        )
        let serverEvent = ServerEvent(rawEvent: rawEvent, message: nil)

        XCTAssertEqual(serverEvent.id, rawEvent.id)
        XCTAssertEqual(serverEvent.name, rawEvent.name)
        XCTAssertEqual(serverEvent.data, rawEvent.data)
        XCTAssertEqual(serverEvent.retry, rawEvent.retry)
    }
}
