import XCTest
import CoreMedia
import CoreImage.CIFilterBuiltins
import VideoToolbox
import TestHelpers
import SnapshotTesting
@testable import PexipVideoFilters

final class VideoFilterTests: XCTestCase {
    private let context = CIContext()
    private let size = CGSize(width: 300, height: 300)

    // MARK: - Tests

    func testCustomVideoFilter() throws {
        let filter = CustomVideoFilter(ciFilter: .sepiaTone(), ciContext: context)
        let image = try processPixelBuffer(with: filter)
        assertSnapshot(matching: image, as: .image, named: snapshotName)
    }

    #if os(macOS)

    // Vision segmentation doesn't work properly on iOS simulator
    @available(macOS 12.0, *)
    func testSegmentationVideoFilter() throws {
        let filter = SegmentationVideoFilter(
            segmenter: VisionPersonSegmenter(),
            backgroundFilter: AccelerateBlurFilter(kind: .tent, ciContext: context),
            globalFilters: [],
            ciContext: context
        )
        let image = try processPixelBuffer(with: filter)
        assertSnapshot(matching: image, as: .image, named: snapshotName)
    }

    // Vision segmentation doesn't work properly on iOS simulator
    @available(macOS 12.0, *)
    func testSegmentationVideoFilterWithGlobalFilters() throws {
        let filter = SegmentationVideoFilter(
            segmenter: VisionPersonSegmenter(),
            backgroundFilter: GaussianBlurFilter(radius: 30),
            globalFilters: [.photoEffectNoir()],
            ciContext: context
        )
        let image = try processPixelBuffer(with: filter)
        assertSnapshot(matching: image, as: .image, named: snapshotName)
    }

    #endif

    // MARK: - Test helpers

    #if os(iOS)
    private typealias Image = UIImage
    #else
    private typealias Image = NSImage
    #endif

    private func processPixelBuffer(with filter: VideoFilter) throws -> Image {
        let testImage = try XCTUnwrap(Bundle.module.testImage())
        let pixelBuffer = try XCTUnwrap(
            testImage.pixelBuffer(
                withTemplate: try XCTUnwrap(
                    CMSampleBuffer.stub(
                        width: Int(size.width),
                        height: Int(size.height),
                        pixelFormat: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
                    ).imageBuffer
                ),
                ciContext: context
            )
        )
        let newPixelBuffer = filter.processPixelBuffer(pixelBuffer, orientation: .up)
        var newCGImage: CGImage!

        VTCreateCGImageFromCVPixelBuffer(newPixelBuffer, options: nil, imageOut: &newCGImage)

        XCTAssertEqual(CVPixelBufferGetWidth(newPixelBuffer), 300)
        XCTAssertEqual(CVPixelBufferGetHeight(newPixelBuffer), 300)
        XCTAssertEqual(
            CVPixelBufferGetPixelFormatType(newPixelBuffer),
            kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
        )

        #if os(iOS)
        return UIImage(cgImage: newCGImage)
        #else
        return NSImage(
            cgImage: newCGImage,
            size: NSSize(width: size.width, height: size.height)
        )
        #endif
    }
}
