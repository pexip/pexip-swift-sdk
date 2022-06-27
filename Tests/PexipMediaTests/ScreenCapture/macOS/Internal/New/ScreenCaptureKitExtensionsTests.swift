#if os(macOS)

import XCTest
@testable import PexipMedia

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
        ShareableContentMock.displays.removeAll()
        ShareableContentMock.windows.removeAll()
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
