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

final class RegexTests: XCTestCase {
    func testMatchEntire() {
        XCTAssertEqual(Regex("^a$").match("a")?.groupValue(at: 0), "a")
        XCTAssertNil(Regex("^a$").match("a")?.groupValue(at: 1))
        XCTAssertNil(Regex("^a$").match("ba")?.groupValue(at: 0))

        let id = UUID().uuidString
        let string = "line1\r\nkey=id:\(id)\r\nline3"

        XCTAssertEqual(
            Regex(".*\\bkey=id:(.*)").match(string)?.groupValue(at: 1),
            id
        )
    }
}
