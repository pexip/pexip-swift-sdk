import CoreImage

#if os(macOS)

import XCTest
@testable import PexipScreenCapture

final class LegacyWindowTests: XCTestCase {
    private var window: Window!

    // MARK: - Setup

    override func setUpWithError() throws {
        try super.setUpWithError()
        window = try XCTUnwrap(LegacyWindow.stub)
    }

    // MARK: - Tests

    func testInit() {
        XCTAssertEqual(window.windowID, 1)
        XCTAssertEqual(window.title, "Window 1")
        XCTAssertNil(window.application)
        XCTAssertEqual(
            window.frame,
            CGRect(x: 0, y: 0, width: 1920, height: 1080)
        )
        XCTAssertTrue(window.isOnScreen)
        XCTAssertEqual(window.windowLayer, 0)
    }

    func testInitWithoutWindowID() {
        var info = LegacyWindow.stubInfo()
        info.removeValue(forKey: kCGWindowNumber)

        XCTAssertNil(LegacyWindow(info: info))
    }

    func testInitWithoutFrame() {
        var info = LegacyWindow.stubInfo()
        info.removeValue(forKey: kCGWindowBounds)

        XCTAssertNil(LegacyWindow(info: info))
    }

    func testInitWithoutIsOnscreen() {
        var info = LegacyWindow.stubInfo()
        info.removeValue(forKey: kCGWindowIsOnscreen)

        XCTAssertNil(LegacyWindow(info: info))
    }

    func testInitWithoutWindowLayer() {
        var info = LegacyWindow.stubInfo()
        info.removeValue(forKey: kCGWindowLayer)

        XCTAssertNil(LegacyWindow(info: info))
    }

    func testWidth() {
        XCTAssertEqual(window.width, 1920)
    }

    func testHeight() {
        XCTAssertEqual(window.height, 1080)
    }

    func testAspectRatio() {
        XCTAssertEqual(window.aspectRatio, 1920/1080)
    }

    func testVideoDimensions() {
        XCTAssertEqual(window.videoDimensions.width, 1920)
        XCTAssertEqual(window.videoDimensions.height, 1080)
    }
}

// MARK: - Stubs

extension LegacyWindow {
    static func stubInfo(withId id: Int = 1) -> [CFString: Any] {
        return [
            kCGWindowNumber: id,
            kCGWindowName: "Window 1",
            kCGWindowBounds: CGRect(
                x: 0,
                y: 0,
                width: 1920,
                height: 1080
            ).dictionaryRepresentation,
            kCGWindowIsOnscreen: true,
            kCGWindowLayer: 0
        ]
    }

    static var stub: LegacyWindow? {
        LegacyWindow(info: stubInfo())
    }
}

extension CGImage {
    static func image(
        withColor color: NSColor,
        width: Int = 1,
        height: Int = 1
    ) -> CGImage? {
        CIContext().createCGImage(
            CIImage(color: CIColor(color: color)!),
            from: CGRect(x: 0, y: 0, width: width, height: height)
        )
    }
}

#endif
