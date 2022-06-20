#if os(macOS)

import XCTest
@testable import PexipMedia

final class LegacyDisplayTests: XCTestCase {
    func testInit() {
        let displayMode = DisplayModeMock(width: 1920, height: 1080)
        let display = LegacyDisplay(
            displayID: 1,
            displayMode: { _ in displayMode }
        )

        XCTAssertEqual(display?.displayID, 1)
        XCTAssertEqual(display?.width, displayMode.width)
        XCTAssertEqual(display?.height, displayMode.height)
    }

    func testInitWithNoDisplayMode() {
        let display = LegacyDisplay(
            displayID: 1,
            displayMode: { _ in nil }
        )

        XCTAssertNil(display)
    }
}

// MARK: - Stubs

extension LegacyDisplay {
    static let stub = LegacyDisplay(
        displayID: 0,
        width: 1920,
        height: 1080
    )
}

// MARK: - Mocks

struct DisplayModeMock: DisplayMode {
    let width: Int
    let height: Int
}

#endif
