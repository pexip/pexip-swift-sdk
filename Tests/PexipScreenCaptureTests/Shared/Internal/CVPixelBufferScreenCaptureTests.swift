//
// Copyright 2022-2023 Pexip AS
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
import CoreVideo
@testable import PexipScreenCapture

final class CVPixelBufferScreenCaptureTests: XCTestCase {
    private let width = 1920
    private let height = 1080
    private let pixelFormat = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
    private var pixelBuffer: CVPixelBuffer!

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        var pixelBuffer: CVPixelBuffer?

        CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            pixelFormat,
            nil,
            &pixelBuffer
        )

        self.pixelBuffer = pixelBuffer
    }

    // MARK: - Tests

    func testPixelFormat() {
        XCTAssertEqual(pixelBuffer.pixelFormat, pixelFormat)
    }

    func testWidth() {
        XCTAssertEqual(pixelBuffer.width, UInt32(width))
    }

    func testHeight() {
        XCTAssertEqual(pixelBuffer.height, UInt32(height))
    }
}
