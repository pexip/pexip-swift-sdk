//
// Copyright 2022-2024 Pexip AS
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
@testable import PexipScreenCapture

final class BroadcastFpsTests: XCTestCase {
    func testInit() {
        XCTAssertEqual(BroadcastFps(value: nil).value, 15)
        XCTAssertEqual(BroadcastFps(value: 25).value, 25)
        XCTAssertEqual(BroadcastFps(value: 60).value, 30)
    }
}

#endif
