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
import CoreMedia
@testable import PexipScreenCapture

final class LegacyScreenMediaSourceEnumeratorTests: XCTestCase {
    private var enumerator: LegacyScreenMediaSourceEnumerator!
    private let displayMode = DisplayModeMock(width: 1920, height: 1080)

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        enumerator = LegacyScreenMediaSourceEnumerator()
    }

    // MARK: - Tests

    func testGetShareableDisplays() async throws {
        enumerator.displayMode = { [weak self] _ in self?.displayMode }
        enumerator.getOnlineDisplayList = { _, displays, count -> CGError in
            var displaysSource: [UInt32] = [1, 2]
            displays?.initialize(from: &displaysSource, count: displaysSource.count)

            var countSource = UInt32(displaysSource.count)
            count?.initialize(from: &countSource, count: 1)
            return .success
        }

        let displays = try await enumerator.getShareableDisplays()
        let expectedDisplays = [
            LegacyDisplay(
                displayID: 1,
                width: displayMode.width,
                height: displayMode.height
            ),
            LegacyDisplay(
                displayID: 2,
                width: displayMode.width,
                height: displayMode.height
            )
        ]

        XCTAssertEqual(displays as? [LegacyDisplay], expectedDisplays)
    }

    func testGetShareableDisplaysWithErrorOnDisplayCount() async throws {
        enumerator.getOnlineDisplayList = { maxDisplays, _, _ -> CGError in
            return maxDisplays == .max ? .failure : .success
        }

        do {
            _ = try await enumerator.getShareableDisplays()
            XCTFail("Should fail with error")
        } catch {
            XCTAssertEqual(error as? ScreenCaptureError, .cgError(.failure))
        }
    }

    func testGetShareableDisplaysWithErrorOnDisplayList() async throws {
        enumerator.getOnlineDisplayList = { maxDisplays, _, _ -> CGError in
            return maxDisplays == .max ? .success : .failure
        }

        do {
            _ = try await enumerator.getShareableDisplays()
            XCTFail("Should fail with error")
        } catch {
            XCTAssertEqual(error as? ScreenCaptureError, .cgError(.failure))
        }
    }

    func testGetAllOnScreenWindows() async throws {
        enumerator.getWindowInfoList = { _, _ -> CFArray? in
            return [LegacyWindow.stubInfo()] as CFArray
        }

        let windows = try await enumerator.getAllOnScreenWindows()
        XCTAssertEqual(windows.count, 1)
        XCTAssertEqual(windows.first?.windowID, LegacyWindow.stub?.windowID)
    }

    func testGetAllOnScreenWindowsWithEmptyWindowInfoList() async throws {
        enumerator.getWindowInfoList = { _, _ -> CFArray? in
            return [] as CFArray
        }

        let windows = try await enumerator.getAllOnScreenWindows()
        XCTAssertEqual(windows.count, 0)
    }

    func testGetAllOnScreenWindowsWithNoWindowInfoList() async throws {
        enumerator.getWindowInfoList = { _, _ -> CFArray? in
            return nil
        }

        let windows = try await enumerator.getAllOnScreenWindows()
        XCTAssertEqual(windows.count, 0)
    }

    func testGetAllOnScreenWindowsWithInvalidWindowInfoList() async throws {
        enumerator.getWindowInfoList = { _, _ -> CFArray? in
            return [""] as CFArray
        }

        let windows = try await enumerator.getAllOnScreenWindows()
        XCTAssertEqual(windows.count, 0)
    }

    func testPermissionSettingsURL() {
        let prefix = "x-apple.systempreferences:com.apple.preference.security"
        let setting = "Privacy_ScreenRecording"
        let url = URL(string: "\(prefix)?\(setting)")

        XCTAssertEqual(enumerator.permissionSettingsURL, url)
    }

    func testGetShareableWindows() async throws {
        var info1 = LegacyWindow.stubInfo(withId: 1)
        info1[kCGWindowOwnerPID] = 1
        info1[kCGWindowOwnerName] = "App 1"

        var info2 = LegacyWindow.stubInfo(withId: 2)
        info2[kCGWindowLayer] = 1
        info2[kCGWindowOwnerPID] = 1
        info2[kCGWindowOwnerName] = "App 1"

        var info3 = LegacyWindow.stubInfo(withId: 3)
        info3[kCGWindowName] = nil
        info3[kCGWindowOwnerPID] = 1
        info3[kCGWindowOwnerName] = "App 1"

        var info4 = LegacyWindow.stubInfo(withId: 4)
        info4[kCGWindowName] = ""
        info4[kCGWindowOwnerPID] = 1
        info4[kCGWindowOwnerName] = "App 1"

        var info5 = LegacyWindow.stubInfo(withId: 5)
        info5[kCGWindowOwnerPID] = nil

        var info6 = LegacyWindow.stubInfo(withId: 6)
        info6[kCGWindowOwnerPID] = 2
        info6[kCGWindowOwnerName] = "App 2"

        enumerator.workspace = WorkspaceMock(
            runningApplications: [
                RunningApplicationMock(
                    processIdentifier: pid_t(1),
                    bundleIdentifier: "com.pexip.TestApp"
                ),
                RunningApplicationMock(
                    processIdentifier: pid_t(2),
                    bundleIdentifier: try XCTUnwrap(Bundle.main.bundleIdentifier)
                )
            ]
        )

        enumerator.getWindowInfoList = { _, _ -> CFArray? in
            return [info1, info2, info3, info4, info5, info6] as CFArray
        }

        let windows = try await enumerator.getShareableWindows()
        XCTAssertEqual(windows.count, 1)
        XCTAssertEqual(windows.first?.windowID, 1)
    }
}

#endif
