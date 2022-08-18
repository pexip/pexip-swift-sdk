import XCTest
import CoreGraphics
import CoreMedia
import TestHelpers
@testable import PexipVideoFilters

final class CoreImageVideoFiltersTests: XCTestCase {
    private let context = CIContext()

    // MARK: - Tests

    func testResizedImage() throws {
        let cgImage = try XCTUnwrap(CGImage.image(width: 100, height: 100))
        let image = CIImage(cgImage: cgImage)
        let resizedImage = image.resizedImage(for: CGSize(width: 80, height: 50))

        XCTAssertEqual(resizedImage.extent, CGRect(x: 0, y: 0, width: 80, height: 50))
    }

    func testScaledToFill() throws {
        let cgImage = try XCTUnwrap(CGImage.image(width: 100, height: 100))
        let image = CIImage(cgImage: cgImage)
        let scaledImage = image.scaledToFill(CGSize(width: 80, height: 50))

        XCTAssertEqual(scaledImage.extent, CGRect(x: 0, y: 0, width: 80, height: 50))
    }

    func testCIImageToPixelBuffer() throws {
        let cgImage = try XCTUnwrap(CGImage.image(width: 100, height: 100))
        let template = CMSampleBuffer.stub(
            width: 100,
            height: 100,
            pixelFormat: kCVPixelFormatType_32BGRA
        ).imageBuffer
        let image = CIImage(cgImage: cgImage)
        let pixelBuffer = try XCTUnwrap(
            image.pixelBuffer(
                withTemplate: try XCTUnwrap(template),
                ciContext: context
            )
        )

        XCTAssertEqual(CVPixelBufferGetWidth(pixelBuffer), 100)
        XCTAssertEqual(CVPixelBufferGetHeight(pixelBuffer), 100)
        XCTAssertEqual(
            CVPixelBufferGetPixelFormatType(pixelBuffer),
            kCVPixelFormatType_32BGRA
        )
    }
}
