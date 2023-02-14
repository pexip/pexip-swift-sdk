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
import WebRTC
@testable import PexipRTC

final class IceConnectionStateTests: XCTestCase {
    func testInit() {
        XCTAssertEqual(IceConnectionState(.new), .new)
        XCTAssertEqual(IceConnectionState(.checking), .checking)
        XCTAssertEqual(IceConnectionState(.connected), .connected)
        XCTAssertEqual(IceConnectionState(.completed), .completed)
        XCTAssertEqual(IceConnectionState(.failed), .failed)
        XCTAssertEqual(IceConnectionState(.disconnected), .disconnected)
        XCTAssertEqual(IceConnectionState(.closed), .closed)
        XCTAssertEqual(IceConnectionState(.count), .count)
        XCTAssertEqual(IceConnectionState(.init(rawValue: 1001)!), .unknown)
    }

    func testDescription() {
        for state in IceConnectionState.allCases {
            XCTAssertEqual(state.description, state.rawValue.capitalized)
        }
    }
}
