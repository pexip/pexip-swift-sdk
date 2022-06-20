#if os(macOS)

import XCTest
@testable import PexipMedia

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
