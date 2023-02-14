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

final class LegacyRunningApplicationTests: XCTestCase {
    private let processIdentifier = 100
    private var info: [CFString: Any]!
    private var workspace: WorkspaceMock!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        info = [
            kCGWindowOwnerPID: processIdentifier,
            kCGWindowOwnerName: "Test App"
        ]
        workspace = WorkspaceMock(runningApplications: [RunningApplicationMock(
            processIdentifier: pid_t(processIdentifier),
            bundleIdentifier: "com.pexip.TestApp"
        )])
    }

    // MARK: - Tests

    func testInit() {
        let application = LegacyRunningApplication(
            info: info,
            workspace: workspace
        )

        XCTAssertEqual(application?.processID, pid_t(processIdentifier))
        XCTAssertEqual(application?.applicationName, "Test App")
        XCTAssertEqual(application?.bundleIdentifier, "com.pexip.TestApp")
    }

    func testInitWithoutProcessID() throws {
        var info = try XCTUnwrap(info)
        info.removeValue(forKey: kCGWindowOwnerPID)

        let application = LegacyRunningApplication(
            info: info,
            workspace: workspace
        )

        XCTAssertNil(application)
    }

    func testInitWithoutApplicationName() throws {
        var info = try XCTUnwrap(info)
        info.removeValue(forKey: kCGWindowOwnerName)

        let application = LegacyRunningApplication(
            info: info,
            workspace: workspace
        )

        XCTAssertNil(application)
    }

    func testInitWithoutBundleIdentifier() {
        let application = LegacyRunningApplication(
            info: info,
            workspace: WorkspaceMock(runningApplications: [])
        )

        XCTAssertNil(application)
    }

    func testLoadAppIcon() {
        workspace.urlForApplication = URL(string: "https://pexip.com")

        let application = LegacyRunningApplication(
            info: info,
            workspace: workspace
        )
        let icon = application?.loadAppIcon(workspace: workspace)

        XCTAssertEqual(icon, workspace.icon)
    }

    func testLoadAppIconWithNoPath() {
        workspace.urlForApplication = nil

        let application = LegacyRunningApplication(
            info: info,
            workspace: workspace
        )
        let icon = application?.loadAppIcon(workspace: workspace)

        XCTAssertNil(icon)
    }
}

// MARK: - Mocks

final class WorkspaceMock: NSWorkspace {
    var urlForApplication: URL?
    var icon = NSImage(
        cgImage: CGImage.image(withColor: .red)!,
        size: NSSize(width: 1, height: 1)
    )
    private let _runningApplications: [NSRunningApplication]

    override var runningApplications: [NSRunningApplication] {
        _runningApplications
    }

    init(runningApplications: [NSRunningApplication]) {
        _runningApplications = runningApplications
    }

    override func urlForApplication(
        withBundleIdentifier bundleIdentifier: String
    ) -> URL? {
        urlForApplication
    }

    override func icon(forFile fullPath: String) -> NSImage {
        icon
    }
}

final class RunningApplicationMock: NSRunningApplication {
    private let _processIdentifier: pid_t
    private let _bundleIdentifier: String

    override var processIdentifier: pid_t {
        _processIdentifier
    }

    override var bundleIdentifier: String {
        _bundleIdentifier
    }

    init(processIdentifier: pid_t, bundleIdentifier: String) {
        _processIdentifier = processIdentifier
        _bundleIdentifier = bundleIdentifier
    }
}

#endif
