#if os(iOS)

import XCTest
import CoreMedia
import ImageIO
import ReplayKit
@testable import PexipMedia

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

// MARK: - Stubs

extension CMSampleBuffer {
    static func stub(
        width: Int = 1920,
        height: Int = 1080,
        displayTime: CMTime = CMClockGetTime(CMClockGetHostTimeClock()),
        pixelFormat: OSType = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
        orientation: CGImagePropertyOrientation? = .up
    ) -> CMSampleBuffer {
        var pixelBuffer: CVPixelBuffer?

        CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            pixelFormat,
            nil,
            &pixelBuffer
        )

        var info = CMSampleTimingInfo()
        info.presentationTimeStamp = CMTime.zero
        info.duration = CMTime.invalid
        info.decodeTimeStamp = CMTime.invalid

        var formatDesc: CMFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer!,
            formatDescriptionOut: &formatDesc
        )

        var sampleBuffer: CMSampleBuffer?

        CMSampleBufferCreateReadyWithImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer!,
            formatDescription: formatDesc!,
            sampleTiming: &info,
            sampleBufferOut: &sampleBuffer
        )

        if let orientation = orientation {
            CMSetAttachment(
                sampleBuffer!,
                key: RPVideoSampleOrientationKey as CFString,
                value: orientation.rawValue as CFNumber,
                attachmentMode: 0
            )
        }

        return sampleBuffer!
    }
}

#endif
