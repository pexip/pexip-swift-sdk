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
import Vision
import CoreMedia
import TestHelpers
@testable import PexipVideoFilters

@available(iOS 15.0, *)
@available(macOS 12.0, *)
final class VisionPersonSegmenterTests: XCTestCase {
    private var requestHandler: RequestHandlerMock!
    private var segmenter: VisionPersonSegmenter!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        requestHandler = RequestHandlerMock()
        segmenter = VisionPersonSegmenter(requestHandler: requestHandler)
    }

    // MARK: - Tests

    func testPersonMaskPixelBuffer() throws {
        let pixelBuffer = try XCTUnwrap(CMSampleBuffer.stub().imageBuffer)
        let result = segmenter.personMaskPixelBuffer(from: pixelBuffer)
        let request = requestHandler.requests.first as? VNGeneratePersonSegmentationRequest

        XCTAssertNil(result)
        XCTAssertEqual(request?.qualityLevel, .balanced)
        XCTAssertEqual(request?.outputPixelFormat, kCVPixelFormatType_OneComponent8)
        XCTAssertEqual(requestHandler.pixelBuffer, pixelBuffer)
    }
}

// MARK: - Mocks

private final class RequestHandlerMock: VNSequenceRequestHandler {
    private(set) var requests = [VNRequest]()
    private(set) var pixelBuffer: CVPixelBuffer?

    override func perform(
        _ requests: [VNRequest],
        on pixelBuffer: CVPixelBuffer
    ) throws {
        self.requests = requests
        self.pixelBuffer = pixelBuffer
    }
}
