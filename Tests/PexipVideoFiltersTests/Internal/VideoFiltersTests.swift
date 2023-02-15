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
        assertSnapshot(matching: image, as: .imageOriginal, named: snapshotName)
    }

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
