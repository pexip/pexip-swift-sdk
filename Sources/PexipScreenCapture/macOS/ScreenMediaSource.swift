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

import CoreGraphics
import CoreMedia
import ScreenCaptureKit

/// A source of the screen content for media capture.
@frozen
public enum ScreenMediaSource: Equatable {
    public static func == (lhs: ScreenMediaSource, rhs: ScreenMediaSource) -> Bool {
        switch (lhs, rhs) {
        case let (.display(display1), .display(display2)):
            return display1.displayID == display2.displayID
        case let (.window(window1), .window(window2)):
            return window1.windowID == window2.windowID
        default:
            return false
        }
    }

    case display(Display)
    case window(Window)

    /// Creates a new instance of ``ScreenMediaSourceEnumerator``
    public static func createEnumerator() -> ScreenMediaSourceEnumerator {
        if #available(macOS 12.3, *) {
            // Use ScreenCaptureKit
            // https://developer.apple.com/documentation/screencapturekit
            return NewScreenMediaSourceEnumerator<SCShareableContent>()
        } else {
            // Use Quartz Window Services.
            // https://developer.apple.com/documentation/coregraphics/quartz_window_services
            return LegacyScreenMediaSourceEnumerator()
        }
    }

    /// Creates a new screen media capturer for the specified media source.
    public static func createCapturer(
        for mediaSource: ScreenMediaSource
    ) -> ScreenMediaCapturer {
        if #available(macOS 12.3, *) {
            // Use ScreenCaptureKit
            // https://developer.apple.com/documentation/screencapturekit
            return NewScreenMediaCapturer(
                source: mediaSource,
                streamFactory: SCStreamFactory()
            )
        } else {
            // Use Quartz Window Services.
            // https://developer.apple.com/documentation/coregraphics/quartz_window_services
            switch mediaSource {
            case .display(let display):
                return LegacyDisplayCapturer(display: display)
            case .window(let window):
                return LegacyWindowCapturer(window: window)
            }
        }
    }
}

#endif
