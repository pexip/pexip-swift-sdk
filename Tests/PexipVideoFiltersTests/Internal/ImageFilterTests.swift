import XCTest
import SnapshotTesting
import CoreImage.CIFilterBuiltins
import TestHelpers
@testable import PexipVideoFilters

final class ImageFilterTests: XCTestCase {
    private let context = CIContext()
    private let size = CGSize(width: 300, height: 300)
    #if os(iOS)
    private let platform = "iOS"
    #else
    private let platform = "macOS"
    #endif

    // MARK: - Tests

    func testTentBlur() throws {
        let filter = AccelerateBlurFilter(kind: .tent, ciContext: context)
        let image = try processImage(with: filter)
        assertSnapshot(matching: image, as: .image, named: platform)
    }

    func testBoxBlur() throws {
        let filter = AccelerateBlurFilter(kind: .box, ciContext: context)
        let image = try processImage(with: filter)
        assertSnapshot(matching: image, as: .image, named: platform)
    }

    func testCustomImageFilter() throws {
        let filter = CustomImageFilter(ciFilter: CIFilter.sepiaTone())
        let image = try processImage(with: filter)
        assertSnapshot(matching: image, as: .image, named: platform)
    }

    func testGaussianBlurFilter() throws {
        let filter = GaussianBlurFilter(radius: 30)
        let image = try processImage(with: filter)
        assertSnapshot(matching: image, as: .image, named: platform)
    }

    func testImageReplacementFilter() throws {
        let filter = ImageReplacementFilter(
            image: try XCTUnwrap(
                CGImage.image(
                    width: Int(size.width),
                    height: Int(size.height)
                )
            )
        )
        let image = try processImage(with: filter)
        assertSnapshot(matching: image, as: .image, named: platform)
    }

    func testVideoReplacementFilter() async throws {
        let url = try XCTUnwrap(
            Bundle.module.url(forResource: "testVideo", withExtension: "mp4")
        )
        let filter = VideoReplacementFilter(url: url)

        // 1. First call returns nil since the video needs to be prepared for playing first
        _ = filter.processImage(
            try XCTUnwrap(Bundle.module.testImage()),
            withSize: size,
            orientation: .up
        )

        // 2. Wait for 2 seconds
        try await Task.sleep(nanoseconds: 2 * 1_000_000_000)

        // 3. Process image again
        let image = try processImage(with: filter)
        assertSnapshot(matching: image, as: .image, named: platform)
    }

    // MARK: - Test helpers

    #if os(iOS)
    private typealias Image = UIImage
    #else
    private typealias Image = NSImage
    #endif

    private func processImage(with filter: ImageFilter) throws -> Image {
        let ciImage = try XCTUnwrap(
            filter.processImage(
                try XCTUnwrap(Bundle.module.testImage()),
                withSize: size,
                orientation: .up
            )
        )
        let cgImage = try XCTUnwrap(
            context.createCGImage(ciImage, from: ciImage.extent)
        )

        #if os(iOS)
        return UIImage(cgImage: cgImage)
        #else
        return NSImage(
            cgImage: cgImage,
            size: NSSize(width: size.width, height: size.height)
        )
        #endif
    }
}

// MARK: - Private extensions

extension Bundle {
    func testImage() -> CIImage? {
        #if os(iOS)

        guard let image = UIImage(named: "testImage.jpg", in: self, with: nil),
              let cgImage = image.cgImage
        else {
            return nil
        }

        return CIImage(cgImage: cgImage)

        #else
        let image = self.image(forResource: "testImage.jpg")!

        guard let data = image.tiffRepresentation,
              let bitmapImageRep = NSBitmapImageRep(data: data)
        else {
            return nil
        }

        return CIImage(bitmapImageRep: bitmapImageRep)

        #endif
    }
}
