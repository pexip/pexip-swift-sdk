import CoreMedia
import ReplayKit

#if os(iOS)

import XCTest
import ImageIO
import TestHelpers
@testable import PexipScreenCapture

final class CMSampleBufferBroadcastTests: XCTestCase {
    func testVideoOrientation() {
        let sampleBuffer = CMSampleBuffer.stub(orientation: .down)
        XCTAssertEqual(
            sampleBuffer.videoOrientation,
            CGImagePropertyOrientation.down.rawValue
        )
    }

    func testVideoOrientationDefault() {
        let sampleBuffer = CMSampleBuffer.stub(orientation: nil)
        XCTAssertEqual(
            sampleBuffer.videoOrientation,
            CGImagePropertyOrientation.up.rawValue
        )
    }
}

#endif
