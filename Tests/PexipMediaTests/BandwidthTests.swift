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
@testable import PexipMedia

final class BandwidthTests: XCTestCase {
    func testInit() {
        XCTAssertEqual(Bandwidth(rawValue: 1024)?.rawValue, 1024)
        XCTAssertNil(Bandwidth(rawValue: 10_000))
    }

    func testLow() {
        XCTAssertEqual(Bandwidth.low, Bandwidth(rawValue: 512))
    }

    func testMedium() {
        XCTAssertEqual(Bandwidth.medium, Bandwidth(rawValue: 1264))
    }

    func testHigh() {
        XCTAssertEqual(Bandwidth.high, Bandwidth(rawValue: 2464))
    }

    func testVeryHigh() {
        XCTAssertEqual(Bandwidth.veryHigh, Bandwidth(rawValue: 6144))
    }
}
