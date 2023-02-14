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
import MachO

public extension XCTestCase {
    static let snapshotName: String = {
        #if os(iOS)
        let platform = "iOS"
        #else
        let platform = "macOS"
        #endif

        #if arch(x86_64)
            return "\(platform)_x86_64"
        #else
            return platform
        #endif
    }()

    var snapshotName: String {
        Self.snapshotName
    }

    func wait(
        for operation: (XCTestExpectation) -> Void,
        after: () -> Void,
        timeout: TimeInterval = 0.3
    ) {
        let expectation = expectation(description: "Test expectation")
        operation(expectation)

        after()
        wait(for: [expectation], timeout: timeout)
    }
}
