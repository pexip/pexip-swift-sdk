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
