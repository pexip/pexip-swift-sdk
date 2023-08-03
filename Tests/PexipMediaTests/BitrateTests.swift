//
// Copyright 2023 Pexip AS
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
@testable import PexipMedia

final class BitrateTests: XCTestCase {
    func testBps() {
        let value = UInt.random(in: 0...UInt.max)
        let bitrate = Bitrate.bps(value)
        XCTAssertEqual(bitrate.bps, value)
    }

    func testKbps() throws {
        XCTAssertNil(Bitrate.kbps(UInt.max))

        let value = UInt.random(in: 0...UInt.max / 1_000)
        let bitrate = try XCTUnwrap(Bitrate.kbps(value))
        XCTAssertEqual(bitrate.bps, value * 1_000)
    }

    func testMbps() throws {
        XCTAssertNil(Bitrate.mbps(UInt.max))

        let value = UInt.random(in: 0...UInt.max / 1_000_000)
        let bitrate = try XCTUnwrap(Bitrate.mbps(value))
        XCTAssertEqual(bitrate.bps, value * 1_000_000)
    }
}
