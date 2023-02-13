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
import CoreMedia
import CoreVideo
@testable import PexipScreenCapture

final class VideoFrameTests: XCTestCase {
    private let width = 1920
    private let height = 1080
    private let displayTimeNs: UInt64 = 10_000
    private let pixelFormat = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
    private var pixelBuffer: CVPixelBuffer!
    private var videoFrame: VideoFrame!

    // MARK: - Setup

    override func setUpWithError() throws {
        try super.setUpWithError()

        CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            pixelFormat,
            nil,
            &pixelBuffer
        )

        videoFrame = VideoFrame(
            pixelBuffer: try XCTUnwrap(pixelBuffer),
            contentRect: CGRect(x: 10.7, y: 10.4, width: 1280.8, height: 720.5),
            displayTimeNs: displayTimeNs
        )
    }

    // MARK: - Tests

    func testInitWithoutContentRect() {
        videoFrame = VideoFrame(
            pixelBuffer: pixelBuffer,
            contentRect: nil,
            displayTimeNs: displayTimeNs
        )

        XCTAssertEqual(
            videoFrame.contentRect,
            CGRect(
                x: 0,
                y: 0,
                width: Int(pixelBuffer.width),
                height: Int(pixelBuffer.height)
            )
        )
    }

    func testDefaultOrientation() {
        XCTAssertEqual(videoFrame.orientation, .up)
    }

    func testWidth() {
        XCTAssertEqual(videoFrame.width, UInt32(width))
    }

    func testHeight() {
        XCTAssertEqual(videoFrame.height, UInt32(height))
    }

    func testPixelBufferDimensions() {
        XCTAssertEqual(videoFrame.pixelBufferDimensions.width, Int32(width))
        XCTAssertEqual(videoFrame.pixelBufferDimensions.height, Int32(height))
    }

    func testContentDimensions() {
        XCTAssertEqual(videoFrame.contentDimensions.width, 1280)
        XCTAssertEqual(videoFrame.contentDimensions.height, 720)
    }

    func testAdaptedContentDimensions() {
        let dimensionsA = videoFrame.adaptedContentDimensions(
            to: CMVideoDimensions(width: 1920, height: 1080)
        )
        XCTAssertEqual(dimensionsA.width, 1280)
        XCTAssertEqual(dimensionsA.height, 720)

        #if os(iOS)
        let dimensionsB = videoFrame.adaptedContentDimensions(
            to: CMVideoDimensions(width: 960, height: 540)
        )
        XCTAssertEqual(dimensionsB.width, 960)
        XCTAssertEqual(dimensionsB.height, 540)
        #else
        let dimensionsB = videoFrame.adaptedContentDimensions(
            to: CMVideoDimensions(width: 640, height: 480)
        )
        XCTAssertEqual(dimensionsB.width, 853)
        XCTAssertEqual(dimensionsB.height, 480)
        #endif

        let dimensionsC = videoFrame.adaptedContentDimensions(
            to: CMVideoDimensions(width: 1000, height: 800)
        )
        XCTAssertEqual(dimensionsC.width, 1000)
        XCTAssertEqual(dimensionsC.height, 562)
    }

    func testContentX() {
        XCTAssertEqual(videoFrame.contentX, 10)
    }

    func testContentY() {
        XCTAssertEqual(videoFrame.contentY, 10)
    }
}
