import XCTest
import CoreVideo
@testable import PexipScreenCapture

final class CVPixelBufferScreenCaptureTests: XCTestCase {
    private let width = 1920
    private let height = 1080
    private let pixelFormat = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
    private var pixelBuffer: CVPixelBuffer!

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        var pixelBuffer: CVPixelBuffer?

        CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            pixelFormat,
            nil,
            &pixelBuffer
        )

        self.pixelBuffer = pixelBuffer
    }

    // MARK: - Tests

    func testPixelFormat() {
        XCTAssertEqual(pixelBuffer.pixelFormat, pixelFormat)
    }

    func testWidth() {
        XCTAssertEqual(pixelBuffer.width, UInt32(width))
    }

    func testHeight() {
        XCTAssertEqual(pixelBuffer.height, UInt32(height))
    }
}
