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
@testable import WebRTC
@testable import PexipRTC

final class SignalingStateTests: XCTestCase {
    func testInit() {
        XCTAssertEqual(SignalingState(.stable), .stable)
        XCTAssertEqual(SignalingState(.haveLocalOffer), .haveLocalOffer)
        XCTAssertEqual(SignalingState(.haveLocalPrAnswer), .haveLocalPrAnswer)
        XCTAssertEqual(SignalingState(.haveRemoteOffer), .haveRemoteOffer)
        XCTAssertEqual(SignalingState(.haveRemotePrAnswer), .haveRemotePrAnswer)
        XCTAssertEqual(SignalingState(.closed), .closed)
        XCTAssertEqual(SignalingState(.init(rawValue: 1001)!), .unknown)
    }

    func testDescription() {
        for state in SignalingState.allCases {
            XCTAssertEqual(state.description, state.rawValue.capitalized)
        }
    }
}
