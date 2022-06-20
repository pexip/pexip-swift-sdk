#if os(macOS)

import XCTest
import CoreMedia
@testable import PexipMedia

final class LegacyScreenVideoSourceEnumeratorTests: XCTestCase {
    private var enumerator: LegacyScreenVideoSourceEnumerator!
    private let displayMode = DisplayModeMock(width: 1920, height: 1080)

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        enumerator = LegacyScreenVideoSourceEnumerator()
    }

    // MARK: - Tests

    func testGetShareableDisplays() async throws {
        enumerator.displayMode = { [weak self] _ in self?.displayMode }
        enumerator.getOnlineDisplayList = { (_, displays, count) -> CGError in
            displays?.pointee = 1
            count?.pointee = 2
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
                displayID: 0,
                width: displayMode.width,
                height: displayMode.height
            )
        ]

        XCTAssertEqual(displays as? [LegacyDisplay], expectedDisplays)
    }

    func testGetShareableDisplaysWithErrorOnDisplayCount() async throws {
        enumerator.getOnlineDisplayList = { (maxDisplays, _, _) -> CGError in
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
        enumerator.getOnlineDisplayList = { (maxDisplays, _, _) -> CGError in
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
        enumerator.getWindowInfoList = { option, relativeToWindow -> CFArray? in 
            return [LegacyWindow.stubInfo()] as CFArray
        }

        let windows = try await enumerator.getAllOnScreenWindows()
        XCTAssertEqual(windows.count, 1)
        XCTAssertEqual(windows.first?.windowID, LegacyWindow.stub?.windowID)
    }

    func testGetAllOnScreenWindowsWithEmptyWindowInfoList() async throws {
        enumerator.getWindowInfoList = { option, relativeToWindow -> CFArray? in
            return [] as CFArray
        }

        let windows = try await enumerator.getAllOnScreenWindows()
        XCTAssertEqual(windows.count, 0)
    }

    func testGetAllOnScreenWindowsWithNoWindowInfoList() async throws {
        enumerator.getWindowInfoList = { option, relativeToWindow -> CFArray? in
            return nil
        }

        let windows = try await enumerator.getAllOnScreenWindows()
        XCTAssertEqual(windows.count, 0)
    }

    func testGetAllOnScreenWindowsWithInvalidWindowInfoList() async throws {
        enumerator.getWindowInfoList = { option, relativeToWindow -> CFArray? in
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

        enumerator.getWindowInfoList = { option, relativeToWindow -> CFArray? in
            return [info1, info2, info3, info4, info5, info6] as CFArray
        }

        let windows = try await enumerator.getShareableWindows()
        XCTAssertEqual(windows.count, 1)
        XCTAssertEqual(windows.first?.windowID, 1)
    }
}

#endif
