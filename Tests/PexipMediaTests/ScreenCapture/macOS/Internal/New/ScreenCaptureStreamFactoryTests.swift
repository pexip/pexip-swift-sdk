#if os(macOS)

import XCTest
@testable import PexipMedia

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
            [PexipMedia.LegacyRunningApplication(
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
