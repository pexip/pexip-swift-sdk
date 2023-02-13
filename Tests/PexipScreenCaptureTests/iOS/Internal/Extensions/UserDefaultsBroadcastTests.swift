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

#if os(iOS)

import XCTest
@testable import PexipScreenCapture

final class UserDefaultsBroadcastTests: XCTestCase {
    private let suiteName = "Test User Defaults"
    private var userDefaults: UserDefaults!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        userDefaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    // MARK: - Tests

    func testBroadcastFps() {
        XCTAssertNil(userDefaults.broadcastFps)

        userDefaults.broadcastFps = 15
        XCTAssertEqual(userDefaults.broadcastFps, 15)

        userDefaults.broadcastFps = nil
        XCTAssertNil(userDefaults.broadcastFps)
    }

    func testBroadcastKeepAliveDate() {
        XCTAssertNil(userDefaults.broadcastKeepAliveDate)

        let date = Date()
        userDefaults.broadcastKeepAliveDate = date
        XCTAssertEqual(userDefaults.broadcastKeepAliveDate, date)

        userDefaults.broadcastKeepAliveDate = nil
        XCTAssertNil(userDefaults.broadcastKeepAliveDate)
    }
}

#endif
