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

#if canImport(ScreenCaptureKit)
import ScreenCaptureKit
#endif

@available(macOS 12.3, *)
final class NewScreenMediaSourceEnumeratorTests: XCTestCase {
    override func tearDown() {
        ShareableContentMock.clear()
        super.tearDown()
    }

    // MARK: - Tests

    func testGetShareableDisplays() async throws {
        let display = LegacyDisplay.stub
        ShareableContentMock.displays = [display]

        let enumetator = NewScreenMediaSourceEnumerator<ShareableContentMock>()
        let displays = try await enumetator.getShareableDisplays()

        XCTAssertEqual(displays.count, 1)
        XCTAssertEqual(displays as? [LegacyDisplay], [display])
    }

    func testGetAllOnScreenWindows() async throws {
        let window = try XCTUnwrap(LegacyWindow.stub)
        ShareableContentMock.windows = [window]

        let enumetator = NewScreenMediaSourceEnumerator<ShareableContentMock>()
        let windows = try await enumetator.getAllOnScreenWindows()

        XCTAssertEqual(windows.count, 1)
        XCTAssertEqual(windows.first?.windowID, window.windowID)
    }
}

#endif
