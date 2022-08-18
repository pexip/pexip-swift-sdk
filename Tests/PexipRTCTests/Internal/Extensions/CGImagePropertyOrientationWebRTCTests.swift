import XCTest
import WebRTC
import PexipMedia
@testable import PexipRTC

final class CGImagePropertyOrientationWebRTCTests: XCTestCase {
    func testRtcRotation() {
        XCTAssertEqual(CGImagePropertyOrientation.up.rtcRotation, ._0)
        XCTAssertEqual(CGImagePropertyOrientation.upMirrored.rtcRotation, ._0)
        XCTAssertEqual(CGImagePropertyOrientation.down.rtcRotation, ._0)
        XCTAssertEqual(CGImagePropertyOrientation.downMirrored.rtcRotation, ._0)
        XCTAssertEqual(CGImagePropertyOrientation(rawValue: 1001)?.rtcRotation, ._0)

        XCTAssertEqual(CGImagePropertyOrientation.left.rtcRotation, ._90)
        XCTAssertEqual(CGImagePropertyOrientation.leftMirrored.rtcRotation, ._90)

        XCTAssertEqual(CGImagePropertyOrientation.right.rtcRotation, ._270)
        XCTAssertEqual(CGImagePropertyOrientation.rightMirrored.rtcRotation, ._270)
    }

    func testInitWithRtcRotation() {
        XCTAssertEqual(CGImagePropertyOrientation(rtcRotation: ._0), .up)
        XCTAssertEqual(CGImagePropertyOrientation(rtcRotation: ._90), .left)
        XCTAssertEqual(CGImagePropertyOrientation(rtcRotation: ._270), .right)
        XCTAssertEqual(CGImagePropertyOrientation(rtcRotation: ._180), .down)
        XCTAssertEqual(
            CGImagePropertyOrientation(rtcRotation: .init(rawValue: 1001)!), .up
        )
    }
}
