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
import WebRTC
import PexipMedia
@testable import PexipRTC

final class CGImagePropertyOrientationWebRTCTests: XCTestCase {
    func testRtcRotation() {
        XCTAssertEqual(CGImagePropertyOrientation.up.rtcRotation, ._0)
        XCTAssertEqual(CGImagePropertyOrientation.upMirrored.rtcRotation, ._0)
        XCTAssertEqual(CGImagePropertyOrientation.down.rtcRotation, ._0)
        XCTAssertEqual(CGImagePropertyOrientation.downMirrored.rtcRotation, ._0)
        XCTAssertEqual(CGImagePropertyOrientation(rawValue: 1001)?.rtcRotation, ._0)

        XCTAssertEqual(CGImagePropertyOrientation.left.rtcRotation, ._90)
        XCTAssertEqual(CGImagePropertyOrientation.leftMirrored.rtcRotation, ._90)

        XCTAssertEqual(CGImagePropertyOrientation.right.rtcRotation, ._270)
        XCTAssertEqual(CGImagePropertyOrientation.rightMirrored.rtcRotation, ._270)
    }

    func testInitWithRtcRotation() {
        XCTAssertEqual(CGImagePropertyOrientation(rtcRotation: ._0), .up)
        XCTAssertEqual(CGImagePropertyOrientation(rtcRotation: ._90), .left)
        XCTAssertEqual(CGImagePropertyOrientation(rtcRotation: ._270), .right)
        XCTAssertEqual(CGImagePropertyOrientation(rtcRotation: ._180), .down)
        XCTAssertEqual(
            CGImagePropertyOrientation(rtcRotation: .init(rawValue: 1001)!), .up
        )
    }
}
