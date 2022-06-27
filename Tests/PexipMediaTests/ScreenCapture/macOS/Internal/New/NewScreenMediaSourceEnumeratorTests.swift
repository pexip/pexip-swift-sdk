#if os(macOS)

import XCTest
@testable import PexipMedia

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
