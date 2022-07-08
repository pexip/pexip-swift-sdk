import XCTest
import CoreGraphics
@testable import PexipMedia

final class CoreGraphicsVideoFiltersTests: XCTestCase {
    func testCGImageScaledToFill() {
        let image = CGImage.image(width: 100, height: 100)
        let scaledImage = image?.scaledToFill(.init(width: 80, height: 50))

        XCTAssertEqual(scaledImage?.width, 80)
        XCTAssertEqual(scaledImage?.height, 50)
    }

    func testCGSizeAspectFillSize() {
        var size = CGSize(width: 100, height: 80).aspectFillSize(
            for: CGSize(width: 100, height: 100)
        )
        XCTAssertEqual(size.width, 125)
        XCTAssertEqual(size.height, 100)

        size = CGSize(width: 80, height: 100).aspectFillSize(
            for: CGSize(width: 100, height: 100)
        )
        XCTAssertEqual(size.width, 100)
        XCTAssertEqual(size.height, 125)
    }

    func testCGImagePropertyOrientationIsVertical() {
        XCTAssertTrue(CGImagePropertyOrientation.up.isVertical)
        XCTAssertTrue(CGImagePropertyOrientation.upMirrored.isVertical)
        XCTAssertTrue(CGImagePropertyOrientation.down.isVertical)
        XCTAssertTrue(CGImagePropertyOrientation.downMirrored.isVertical)

        XCTAssertFalse(CGImagePropertyOrientation.left.isVertical)
        XCTAssertFalse(CGImagePropertyOrientation.leftMirrored.isVertical)
        XCTAssertFalse(CGImagePropertyOrientation.right.isVertical)
        XCTAssertFalse(CGImagePropertyOrientation.rightMirrored.isVertical)
        XCTAssertFalse(CGImagePropertyOrientation(rawValue: 1001)?.isVertical == true)
    }
}
