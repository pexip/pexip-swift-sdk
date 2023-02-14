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
import CoreGraphics
@testable import PexipMedia

final class VideoContentTests: XCTestCase {
    func testAspectRatio() {
        XCTAssertEqual(
            VideoContentMode.fit16x9.aspectRatio,
            CGSize(width: 16, height: 9)
        )
        XCTAssertEqual(
            VideoContentMode.fit4x3.aspectRatio,
            CGSize(width: 4, height: 3)
        )
        XCTAssertEqual(
            VideoContentMode.fitAspectRatio(CGSize(width: 100, height: 80)).aspectRatio,
            CGSize(width: 100, height: 80)
        )
        XCTAssertEqual(
            VideoContentMode.fitQualityProfile(.high).aspectRatio,
            QualityProfile.high.aspectRatio
        )
        XCTAssertNil(VideoContentMode.fill.aspectRatio)
        XCTAssertNil(VideoContentMode.fit.aspectRatio)
    }
}
