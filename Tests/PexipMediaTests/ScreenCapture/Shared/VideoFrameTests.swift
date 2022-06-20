import XCTest
import CoreVideo
@testable import PexipMedia

final class VideoFrameTests: XCTestCase {
    private let width = 1920
    private let height = 1080
    private let displayTimeNs: UInt64 = 10000
    private let elapsedTimeNs: UInt64 = 500
    private let pixelFormat = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
    private var videoFrame: VideoFrame!

    // MARK: - Setup

    override func setUpWithError() throws {
        try super.setUpWithError()

        var pixelBuffer: CVPixelBuffer?

        CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            pixelFormat,
            nil,
            &pixelBuffer
        )


        videoFrame = VideoFrame(
            pixelBuffer: try XCTUnwrap(pixelBuffer),
            displayTimeNs: displayTimeNs,
            elapsedTimeNs: elapsedTimeNs
        )
    }

    // MARK: - Tests

    func testDefaultOrientation() {
        XCTAssertEqual(videoFrame.orientation, .up)
    }

    func testWidth() {
        XCTAssertEqual(videoFrame.width, UInt32(width))
    }

    func testHeight() {
        XCTAssertEqual(videoFrame.height, UInt32(height))
    }

    func testDimensions() {
        XCTAssertEqual(videoFrame.dimensions.width, Int32(width))
        XCTAssertEqual(videoFrame.dimensions.height, Int32(height))
    }
}
