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
@testable import PexipInfinityClient

final class FailureEventTests: XCTestCase {
    func testInit() {
        let id = UUID()
        let error = URLError(.badURL)
        let event = FailureEvent(
            id: id,
            error: error
        )

        XCTAssertEqual(event.id, id)
        XCTAssertEqual(event.error as? URLError, error)
    }

    func testHashable() {
        let id = UUID()
        let error = URLError(.badURL)
        let event = FailureEvent(
            id: id,
            error: error
        )

        var hasher = Hasher()
        hasher.combine(id)
        hasher.combine(error.localizedDescription)
        let hashValue = hasher.finalize()

        XCTAssertEqual(event.hashValue, hashValue)
    }

    func testEquatable() {
        let id = UUID()
        let error = URLError(.badURL)

        XCTAssertEqual(
            FailureEvent(
                id: id,
                error: error
            ),
            FailureEvent(
                id: id,
                error: error
            )
        )

        XCTAssertNotEqual(
            FailureEvent(
                id: id,
                error: error
            ),
            FailureEvent(
                id: id,
                error: URLError(.unknown)
            )
        )
    }
}
