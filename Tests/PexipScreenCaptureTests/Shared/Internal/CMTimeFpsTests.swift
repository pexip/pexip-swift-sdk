import XCTest
import CoreMedia
@testable import PexipScreenCapture

final class CMTimeFpsTests: XCTestCase {
    func testInitWithFps() {
        let time = CMTime(fps: 30)

        XCTAssertEqual(time.value, 1)
        XCTAssertEqual(time.timescale, 30)
        XCTAssertTrue(time.isValid)
    }
}
