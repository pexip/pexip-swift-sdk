//
// Copyright 2022 Pexip AS
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#if os(macOS)

import XCTest
@testable import PexipScreenCapture

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
