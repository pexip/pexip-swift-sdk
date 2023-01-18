import XCTest
import CoreGraphics
@testable import PexipMedia

final class VideoContentTests: XCTestCase {
    func testAspectRatio() {
        XCTAssertEqual(
            VideoContentMode.fit16x9.aspectRatio,
            CGSize(width: 16, height: 9)
        )
        XCTAssertEqual(
            VideoContentMode.fit4x3.aspectRatio,
            CGSize(width: 4, height: 3)
        )
        XCTAssertEqual(
            VideoContentMode.fitAspectRatio(CGSize(width: 100, height: 80)).aspectRatio,
            CGSize(width: 100, height: 80)
        )
        XCTAssertEqual(
            VideoContentMode.fitQualityProfile(.high).aspectRatio,
            QualityProfile.high.aspectRatio
        )
        XCTAssertNil(VideoContentMode.fill.aspectRatio)
        XCTAssertNil(VideoContentMode.fit.aspectRatio)
    }
}
