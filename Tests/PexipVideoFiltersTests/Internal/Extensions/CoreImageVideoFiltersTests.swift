import XCTest
import CoreGraphics
@testable import PexipVideoFilters

final class CoreImageVideoFiltersTests: XCTestCase {
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
}
