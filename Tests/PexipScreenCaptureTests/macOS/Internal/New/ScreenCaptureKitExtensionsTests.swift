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
final class ScreenCaptureKitExtensionsTests: XCTestCase {
    override func tearDown() {
        ShareableContentMock.clear()
        super.tearDown()
    }

    func testShareableContentDefaultSelection() async throws {
        let content = try await ShareableContentMock.defaultSelection()

        XCTAssertTrue(content.excludeDesktopWindows)
        XCTAssertTrue(content.onScreenWindowsOnly)
        XCTAssertTrue(content.displays.isEmpty)
        XCTAssertTrue(content.windows.isEmpty)
    }
}

// MARK: - Mocks

struct ShareableContentMock: ShareableContent {
    static var displays = [LegacyDisplay]()
    static var windows = [LegacyWindow]()
    static var applications = [LegacyRunningApplication]()

    let excludeDesktopWindows: Bool
    let onScreenWindowsOnly: Bool
    let displays: [LegacyDisplay]
    let windows: [LegacyWindow]
    let applications: [LegacyRunningApplication]

    static func excludingDesktopWindows(
        _ excludeDesktopWindows: Bool,
        onScreenWindowsOnly: Bool
    ) async throws -> ShareableContentMock {
        ShareableContentMock(
            excludeDesktopWindows: excludeDesktopWindows,
            onScreenWindowsOnly: onScreenWindowsOnly,
            displays: Self.displays,
            windows: Self.windows,
            applications: Self.applications
        )
    }

    static func clear() {
        Self.displays.removeAll()
        Self.windows.removeAll()
    }
}

struct ScreenCaptureContentFilterMock: ScreenCaptureContentFilter {
    private(set) var window: LegacyWindow?
    private(set) var display: LegacyDisplay?
    private(set) var excludedApplications = [LegacyRunningApplication]()
    private(set) var exceptedWindows = [LegacyWindow]()

    init(desktopIndependentWindow window: LegacyWindow) {
        self.window = window
    }

    init(
        display: LegacyDisplay,
        excludingApplications applications: [LegacyRunningApplication],
        exceptingWindows: [LegacyWindow]
    ) {
        self.display = display
        self.excludedApplications = applications
        self.exceptedWindows = exceptingWindows
    }
}

#endif
