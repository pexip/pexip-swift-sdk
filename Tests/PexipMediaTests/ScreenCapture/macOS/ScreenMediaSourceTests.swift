#if os(macOS)

import XCTest
@testable import PexipMedia

#if canImport(ScreenCaptureKit)
import ScreenCaptureKit
#endif

final class ScreenMediaSourceTests: XCTestCase {
    func testEquatable() {
        XCTAssertEqual(
            ScreenMediaSource.display(LegacyDisplay.stub),
            ScreenMediaSource.display(LegacyDisplay.stub)
        )
        XCTAssertNotEqual(
            ScreenMediaSource.display(LegacyDisplay.stub),
            ScreenMediaSource.display(
                LegacyDisplay(displayID: 100, width: 100, height: 100)
            )
        )

        XCTAssertEqual(
            ScreenMediaSource.window(LegacyWindow.stub!),
            ScreenMediaSource.window(LegacyWindow.stub!)
        )
        XCTAssertNotEqual(
            ScreenMediaSource.window(LegacyWindow.stub!),
            ScreenMediaSource.window(
                LegacyWindow(info: LegacyWindow.stubInfo(withId: 1000))!
            )
        )

        XCTAssertNotEqual(
            ScreenMediaSource.window(LegacyWindow.stub!),
            ScreenMediaSource.display(LegacyDisplay.stub)
        )
    }

    func testCreateEnumerator() {
        let enumerator = ScreenMediaSource.createEnumerator()

        if #available(macOS 12.3, *) {
            XCTAssertTrue(
                enumerator is NewScreenMediaSourceEnumerator<SCShareableContent>
            )
        } else {
            XCTAssertTrue(enumerator is LegacyScreenMediaSourceEnumerator)
        }
    }

    func testCreateDisplayCapturer() {
        let display = LegacyDisplay.stub
        let mediaSource = ScreenMediaSource.display(display)
        let capturer = ScreenMediaSource.createCapturer(for: mediaSource)

        if #available(macOS 12.3, *) {
            XCTAssertTrue(capturer is NewScreenMediaCapturer<SCStreamFactory>)
        } else {
            XCTAssertTrue(capturer is LegacyDisplayCapturer)
        }
    }

    func testCreateWindowCapturer() {
        let window = LegacyWindow.stub!
        let mediaSource = ScreenMediaSource.window(window)
        let capturer = ScreenMediaSource.createCapturer(for: mediaSource)

        if #available(macOS 12.3, *) {
            XCTAssertTrue(capturer is NewScreenMediaCapturer<SCStreamFactory>)
        } else {
            XCTAssertTrue(capturer is LegacyWindowCapturer)
        }
    }
}

#endif
