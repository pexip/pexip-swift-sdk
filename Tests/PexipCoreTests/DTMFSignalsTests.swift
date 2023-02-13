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
@testable import PexipCore

final class DTMFSignalsTests: XCTestCase {
    func testInitWithValidRawValue() {
        XCTAssertEqual(DTMFSignals(rawValue: " 01234 ")?.rawValue, "01234")

        do {
            let value = "0123456789*#ABCD"
            XCTAssertEqual(DTMFSignals(rawValue: value)?.rawValue, value)
        }

        do {
            let value = "01234AB"
            XCTAssertEqual(DTMFSignals(rawValue: value)?.rawValue, value)
        }

        do {
            let value = "#ABCD"
            XCTAssertEqual(DTMFSignals(rawValue: value)?.rawValue, value)
        }

        do {
            let value = "*"
            XCTAssertEqual(DTMFSignals(rawValue: value)?.rawValue, value)
        }
    }

    func testInitWithInvalidRawValue() {
        XCTAssertNil(DTMFSignals(rawValue: ""))
        XCTAssertNil(DTMFSignals(rawValue: "01234T"))
        XCTAssertNil(DTMFSignals(rawValue: "Test"))
    }
}
