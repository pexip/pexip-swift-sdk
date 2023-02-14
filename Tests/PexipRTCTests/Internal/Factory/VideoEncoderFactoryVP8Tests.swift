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
@testable import PexipRTC

final class VideoEncoderFactoryVP8Tests: XCTestCase {
    private var factory: VideoEncoderFactoryVP8!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        factory = VideoEncoderFactoryVP8()
    }

    // MARK: - Tests

    func testCreateEncoder() {
        XCTAssertNotNil(factory.createEncoder(.init(name: kRTCVp8CodecName)))
        XCTAssertNil(factory.createEncoder(.init(name: kRTCVp9CodecName)))
    }

    func testSupportedCodecs() {
        XCTAssertEqual(
            factory.supportedCodecs(),
            [RTCVideoCodecInfo(name: kRTCVp8CodecName)]
        )
    }
}
