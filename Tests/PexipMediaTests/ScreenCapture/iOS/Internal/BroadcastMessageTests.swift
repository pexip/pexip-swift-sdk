#if os(iOS)

import XCTest
import CoreVideo
import CoreMedia
@testable import PexipMedia

final class BroadcastMessageTests: XCTestCase {
    private let displayTimeNs = MachAbsoluteTime(mach_absolute_time()).nanoseconds

    func testInitWithSampleBuffer() throws {
        let width = 1920
        let height = 1080
        let pixelFormat = kCVPixelFormatType_32BGRA
        let orientation = CGImagePropertyOrientation.up

        let sampleBuffer = CMSampleBuffer.stub(
            width: width,
            height: height,
            pixelFormat: pixelFormat,
            orientation: orientation
        )
        let data = try XCTUnwrap(sampleBuffer.imageBuffer?.data)
        let message = try XCTUnwrap(
            BroadcastMessage(
                sampleBuffer: sampleBuffer,
                displayTimeNs: displayTimeNs
            )
        )

        XCTAssertEqual(
            message,
            BroadcastMessage(
                header: BroadcastHeader(
                    displayTimeNs: displayTimeNs,
                    pixelFormat: pixelFormat,
                    videoWidth: UInt32(width),
                    videoHeight: UInt32(height),
                    videoOrientation: orientation.rawValue,
                    contentLength: UInt32(data.count)
                ),
                body: data
            )
        )
    }

    func testInitWithSampleBufferWithoutPixelBuffer() throws {
        let sampleBuffer = try CMSampleBuffer(
            dataBuffer: nil,
            formatDescription: nil,
            numSamples: 0,
            sampleTimings: [],
            sampleSizes: [],
            makeDataReadyHandler: { _ in
                return 0
            }
        )
        let message = BroadcastMessage(
            sampleBuffer: sampleBuffer,
            displayTimeNs: displayTimeNs
        )

        XCTAssertNil(message)
    }
}

#endif
