import XCTest
import CoreVideo
@testable import PexipMedia

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

    func testData() throws {
        let data = try XCTUnwrap(pixelBuffer.data)
        let newPixelBuffer = try XCTUnwrap(CVPixelBuffer.pixelBuffer(
            fromData: data,
            width: Int(pixelBuffer.width),
            height: Int(pixelBuffer.height),
            pixelFormat: pixelBuffer.pixelFormat
        ))

        XCTAssertEqual(newPixelBuffer.width, pixelBuffer.width)
        XCTAssertEqual(newPixelBuffer.height, pixelBuffer.height)
        XCTAssertEqual(newPixelBuffer.pixelFormat, pixelBuffer.pixelFormat)
        XCTAssertEqual(
            CVPixelBufferGetBytesPerRow(newPixelBuffer),
            CVPixelBufferGetBytesPerRow(pixelBuffer)
        )
        XCTAssertEqual(
            CVPixelBufferGetPlaneCount(newPixelBuffer),
            CVPixelBufferGetPlaneCount(pixelBuffer)
        )

        for plane in 0..<CVPixelBufferGetPlaneCount(newPixelBuffer) {
            XCTAssertEqual(
                CVPixelBufferGetBytesPerRowOfPlane(newPixelBuffer, plane),
                CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, plane)
            )
            XCTAssertEqual(
                CVPixelBufferGetHeightOfPlane(newPixelBuffer, plane),
                CVPixelBufferGetHeightOfPlane(pixelBuffer, plane)
            )
        }
    }
}
