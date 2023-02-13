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
