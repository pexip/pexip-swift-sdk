//
// Copyright 2022 Pexip AS
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import XCTest
import SnapshotTesting
import CoreImage.CIFilterBuiltins
import TestHelpers
@testable import PexipVideoFilters

final class ImageFilterTests: XCTestCase {
    private let context = CIContext()
    private let size = CGSize(width: 300, height: 300)

    // MARK: - Tests

    func testTentBlur() throws {
        let filter = AccelerateBlurFilter(kind: .tent, ciContext: context)
        let image = try processImage(with: filter)
        assertSnapshot(matching: image, as: .imageOriginal, named: snapshotName)
    }

    func testBoxBlur() throws {
        let filter = AccelerateBlurFilter(kind: .box, ciContext: context)
        let image = try processImage(with: filter)
        assertSnapshot(matching: image, as: .imageOriginal, named: snapshotName)
    }

    func testCustomImageFilter() throws {
        let filter = CustomImageFilter(ciFilter: CIFilter.sepiaTone())
        let image = try processImage(with: filter)
        assertSnapshot(matching: image, as: .imageOriginal, named: snapshotName)
    }

    #if os(iOS)

    func testGaussianBlurFilter() throws {
        let filter = GaussianBlurFilter(radius: 30)
        let image = try processImage(with: filter)
        assertSnapshot(matching: image, as: .imageOriginal, named: snapshotName)
    }

    #endif

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
        assertSnapshot(matching: image, as: .imageOriginal, named: snapshotName)
    }

    #if os(iOS)

    func testVideoReplacementFilter() async throws {
        let expectation = self.expectation(description: "Ready to play")
        let url = try XCTUnwrap(
            Bundle.module.url(forResource: "testVideo", withExtension: "mp4")
        )
        let filter = VideoReplacementFilter(url: url)
        filter.onReadyToPlay = {
            expectation.fulfill()
        }

        // 1. First call returns nil since the video needs to be prepared for playing first
        _ = filter.processImage(
            try XCTUnwrap(Bundle.module.testImage()),
            withSize: size,
            orientation: .up
        )

        wait(for: [expectation], timeout: 3)

        // 2. Wait for 2 seconds
        try await Task.sleep(nanoseconds: 2 * 1_000_000_000)

        // 3. Process image again
        let image = try processImage(with: filter)
        assertSnapshot(matching: image, as: .imageOriginal, named: snapshotName)
    }

    #endif

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

// MARK: - Internal extensions

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

#if os(iOS)

extension Snapshotting where Value == UIImage, Format == UIImage {
    static let imageOriginal = Self.image(precision: 0.7, scale: 1)
}

#else

extension Snapshotting where Value == NSImage, Format == NSImage {
    static let imageOriginal = Self.image(precision: 0.5)
}

#endif
