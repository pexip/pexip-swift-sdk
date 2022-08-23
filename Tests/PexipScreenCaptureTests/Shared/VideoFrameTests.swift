import XCTest
import CoreMedia
import CoreVideo
@testable import PexipScreenCapture

final class VideoFrameTests: XCTestCase {
    private let width = 1920
    private let height = 1080
    private let displayTimeNs: UInt64 = 10_000
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
            contentRect: CGRect(x: 10.7, y: 10.4, width: 1280.8, height: 720.5),
            displayTimeNs: displayTimeNs
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

    func testPixelBufferDimensions() {
        XCTAssertEqual(videoFrame.pixelBufferDimensions.width, Int32(width))
        XCTAssertEqual(videoFrame.pixelBufferDimensions.height, Int32(height))
    }

    func testContentDimensions() {
        XCTAssertEqual(videoFrame.contentDimensions.width, 1280)
        XCTAssertEqual(videoFrame.contentDimensions.height, 720)
    }

    func testAdaptedContentDimensions() {
        let dimensionsA = videoFrame.adaptedContentDimensions(
            to: CMVideoDimensions(width: 1920, height: 1080)
        )
        XCTAssertEqual(dimensionsA.width, 1280)
        XCTAssertEqual(dimensionsA.height, 720)

        #if os(iOS)
        let dimensionsB = videoFrame.adaptedContentDimensions(
            to: CMVideoDimensions(width: 960, height: 540)
        )
        XCTAssertEqual(dimensionsB.width, 960)
        XCTAssertEqual(dimensionsB.height, 540)
        #else
        let dimensionsB = videoFrame.adaptedContentDimensions(
            to: CMVideoDimensions(width: 640, height: 480)
        )
        XCTAssertEqual(dimensionsB.width, 853)
        XCTAssertEqual(dimensionsB.height, 480)
        #endif

        let dimensionsC = videoFrame.adaptedContentDimensions(
            to: CMVideoDimensions(width: 1000, height: 800)
        )
        XCTAssertEqual(dimensionsC.width, 1000)
        XCTAssertEqual(dimensionsC.height, 562)
    }

    func testContentX() {
        XCTAssertEqual(videoFrame.contentX, 10)
    }

    func testContentY() {
        XCTAssertEqual(videoFrame.contentY, 10)
    }
}
