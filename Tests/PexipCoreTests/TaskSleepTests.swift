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

final class TaskSleepTests: XCTestCase {
    func testSleepWithInvalidSeconds() async throws {
        let task = Task<String, Error> {
            try await Task.sleep(seconds: 0)
            return "test"
        }

        do {
            _ = try await task.value
        } catch {
            XCTAssertTrue(error is CancellationError)
        }
    }
}
