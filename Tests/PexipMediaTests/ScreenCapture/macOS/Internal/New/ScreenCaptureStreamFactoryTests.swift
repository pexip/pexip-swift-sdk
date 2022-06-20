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
            videoSource: .display(display)
        )

        XCTAssertEqual(filter.display, display)
        XCTAssertNil(filter.window)
        XCTAssertTrue(filter.excludedWindows.isEmpty)
    }

    func testCreateContentFilterWithWindow() async throws {
        ShareableContentMock.windows = [window]

        let filter = try await factory.createContentFilter(
            videoSource: .window(window)
        )

        XCTAssertEqual(filter.window?.windowID, window.windowID)
        XCTAssertNil(filter.display)
        XCTAssertTrue(filter.excludedWindows.isEmpty)
    }

    func testStartCaptureWihNoDisplayFound() async {
        do {
            ShareableContentMock.displays = []
            _ = try await factory.createContentFilter(
                videoSource: .display(display)
            )
            XCTFail("Should fail with error")
        } catch {
            XCTAssertEqual(error as? ScreenCaptureError, .noScreenVideoSourceAvailable)
        }
    }

    func testStartCaptureWihNoWindowFound() async {
        do {
            ShareableContentMock.windows = []
            _ = try await factory.createContentFilter(
                videoSource: .window(window)
            )
            XCTFail("Should fail with error")
        } catch {
            XCTAssertEqual(error as? ScreenCaptureError, .noScreenVideoSourceAvailable)
        }
    }
}

#endif
