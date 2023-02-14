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
final class ScreenCaptureStreamFactoryTests: XCTestCase {
    private var factory: ScreenCaptureStreamFactoryMock!
    private let display = LegacyDisplay.stub
    private let window = LegacyWindow.stub!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        factory = ScreenCaptureStreamFactoryMock()
    }

    override func tearDown() {
        ShareableContentMock.clear()
        super.tearDown()
    }

    // MARK: - Tests

    func testCreateContentFilterWithDisplay() async throws {
        ShareableContentMock.displays = [display]

        let filter = try await factory.createContentFilter(
            mediaSource: .display(display)
        )

        XCTAssertEqual(filter.display, display)
        XCTAssertNil(filter.window)
        XCTAssertEqual(
            filter.excludedApplications,
            [LegacyRunningApplication(
                processID: 1,
                bundleIdentifier: "com.apple.dt.xctest.tool",
                applicationName: "Test")
            ]
        )
        XCTAssertTrue(filter.exceptedWindows.isEmpty)
    }

    func testCreateContentFilterWithDisplayExcludingApplications() async throws {
        ShareableContentMock.displays = [display]
        ShareableContentMock.applications = [LegacyRunningApplication(
            processID: 1,
            bundleIdentifier: Bundle.main.bundleIdentifier ?? "",
            applicationName: "Test"
        )]

        let filter = try await factory.createContentFilter(
            mediaSource: .display(display)
        )

        XCTAssertEqual(filter.display, display)
        XCTAssertEqual(filter.excludedApplications, ShareableContentMock.applications)
        XCTAssertNil(filter.window)
        XCTAssertTrue(filter.exceptedWindows.isEmpty)
    }

    func testCreateContentFilterWithWindow() async throws {
        ShareableContentMock.windows = [window]

        let filter = try await factory.createContentFilter(
            mediaSource: .window(window)
        )

        XCTAssertEqual(filter.window?.windowID, window.windowID)
        XCTAssertNil(filter.display)
        XCTAssertTrue(filter.excludedApplications.isEmpty)
        XCTAssertTrue(filter.exceptedWindows.isEmpty)
    }

    func testStartCaptureWihNoDisplayFound() async {
        do {
            ShareableContentMock.displays = []
            _ = try await factory.createContentFilter(
                mediaSource: .display(display)
            )
            XCTFail("Should fail with error")
        } catch {
            XCTAssertEqual(error as? ScreenCaptureError, .noScreenMediaSourceAvailable)
        }
    }

    func testStartCaptureWihNoWindowFound() async {
        do {
            ShareableContentMock.windows = []
            _ = try await factory.createContentFilter(
                mediaSource: .window(window)
            )
            XCTFail("Should fail with error")
        } catch {
            XCTAssertEqual(error as? ScreenCaptureError, .noScreenMediaSourceAvailable)
        }
    }
}

#endif
