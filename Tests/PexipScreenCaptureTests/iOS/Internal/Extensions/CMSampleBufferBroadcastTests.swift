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

#if os(iOS)

import XCTest
import ImageIO
import CoreMedia
import TestHelpers
@testable import PexipScreenCapture

final class CMSampleBufferBroadcastTests: XCTestCase {
    func testVideoOrientation() {
        let sampleBuffer = CMSampleBuffer.stub(orientation: .down)
        XCTAssertEqual(
            sampleBuffer.videoOrientation,
            CGImagePropertyOrientation.down.rawValue
        )
    }

    func testVideoOrientationDefault() {
        let sampleBuffer = CMSampleBuffer.stub(orientation: nil)
        XCTAssertEqual(
            sampleBuffer.videoOrientation,
            CGImagePropertyOrientation.up.rawValue
        )
    }
}

#endif
