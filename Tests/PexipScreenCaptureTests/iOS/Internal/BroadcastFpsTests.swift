#if os(iOS)

import XCTest
@testable import PexipScreenCapture

final class BroadcastFpsTests: XCTestCase {
    func testInit() {
        XCTAssertEqual(BroadcastFps(value: nil).value, 15)
        XCTAssertEqual(BroadcastFps(value: 25).value, 25)
        XCTAssertEqual(BroadcastFps(value: 60).value, 30)
    }
}

#endif
