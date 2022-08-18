import XCTest
import Vision
import CoreMedia
@testable import PexipVideoFilters

final class VideoFilterFactoryTests: XCTestCase {
    private var factory: VideoFilterFactory!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        factory = VideoFilterFactory()
    }

    // MARK: - Tests

    @available(iOS 15.0, *)
    @available(macOS 12.0, *)
    func testSegmentation() {
        let filter = factory.segmentation(background: .gaussianBlur(radius: 30))
        XCTAssertTrue(filter is SegmentationVideoFilter)
    }

    func testCustomFilter() {
        let filter = factory.customFilter(.photoEffectNoir())
        XCTAssertTrue(filter is CustomVideoFilter)
    }
}
