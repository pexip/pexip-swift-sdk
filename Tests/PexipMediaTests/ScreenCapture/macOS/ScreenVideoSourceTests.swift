#if os(macOS)

import XCTest
@testable import PexipMedia

#if canImport(ScreenCaptureKit)
import ScreenCaptureKit
#endif

final class ScreenVideoSourceTests: XCTestCase {
    func testEquatable() {
        XCTAssertEqual(
            ScreenVideoSource.display(LegacyDisplay.stub),
            ScreenVideoSource.display(LegacyDisplay.stub)
        )
        XCTAssertNotEqual(
            ScreenVideoSource.display(LegacyDisplay.stub),
            ScreenVideoSource.display(
                LegacyDisplay(displayID: 100, width: 100, height: 100)
            )
        )

        XCTAssertEqual(
            ScreenVideoSource.window(LegacyWindow.stub!),
            ScreenVideoSource.window(LegacyWindow.stub!)
        )
        XCTAssertNotEqual(
            ScreenVideoSource.window(LegacyWindow.stub!),
            ScreenVideoSource.window(
                LegacyWindow(info: LegacyWindow.stubInfo(withId: 1000))!
            )
        )

        XCTAssertNotEqual(
            ScreenVideoSource.window(LegacyWindow.stub!),
            ScreenVideoSource.display(LegacyDisplay.stub)
        )
    }

    func testVideoDimensions() {
        let display = LegacyDisplay.stub
        let videoDimensions1 = ScreenVideoSource.display(display).videoDimensions

        XCTAssertEqual(videoDimensions1.width, display.videoDimensions.width)
        XCTAssertEqual(videoDimensions1.height, display.videoDimensions.height)

        let window = LegacyWindow.stub!
        let videoDimensions2 = ScreenVideoSource.window(window).videoDimensions

        XCTAssertEqual(videoDimensions2.width, window.videoDimensions.width)
        XCTAssertEqual(videoDimensions2.height, window.videoDimensions.height)
    }

    func testCreateEnumerator() {
        let enumerator = ScreenVideoSource.createEnumerator()

        if #available(macOS 12.3, *) {
            XCTAssertTrue(
                enumerator is NewScreenVideoSourceEnumerator<SCShareableContent>
            )
        } else {
            XCTAssertTrue(enumerator is LegacyScreenVideoSourceEnumerator)
        }
    }

    func testCreateDisplayCapturer() {
        let display = LegacyDisplay.stub
        let videoSource = ScreenVideoSource.display(display)
        let capturer = ScreenVideoSource.createCapturer(for: videoSource)

        if #available(macOS 12.3, *) {
            XCTAssertTrue(capturer is NewScreenVideoCapturer<SCStreamFactory>)
        } else {
            XCTAssertTrue(capturer is LegacyDisplayVideoCapturer)
        }
    }

    func testCreateWindowCapturer() {
        let window = LegacyWindow.stub!
        let videoSource = ScreenVideoSource.window(window)
        let capturer = ScreenVideoSource.createCapturer(for: videoSource)

        if #available(macOS 12.3, *) {
            XCTAssertTrue(capturer is NewScreenVideoCapturer<SCStreamFactory>)
        } else {
            XCTAssertTrue(capturer is LegacyWindowVideoCapturer)
        }
    }
}

#endif
