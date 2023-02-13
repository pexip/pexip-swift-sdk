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

#if os(macOS)

import XCTest
@testable import PexipScreenCapture

final class LegacyDisplayTests: XCTestCase {
    func testInit() {
        let displayMode = DisplayModeMock(width: 1920, height: 1080)
        let display = LegacyDisplay(
            displayID: 1,
            displayMode: { _ in displayMode }
        )

        XCTAssertEqual(display?.displayID, 1)
        XCTAssertEqual(display?.width, displayMode.width)
        XCTAssertEqual(display?.height, displayMode.height)
    }

    func testInitWithNoDisplayMode() {
        let display = LegacyDisplay(
            displayID: 1,
            displayMode: { _ in nil }
        )

        XCTAssertNil(display)
    }
}

// MARK: - Stubs

extension LegacyDisplay {
    static let stub = LegacyDisplay(
        displayID: 0,
        width: 1280,
        height: 720
    )
}

// MARK: - Mocks

struct DisplayModeMock: DisplayMode {
    let width: Int
    let height: Int
}

#endif
