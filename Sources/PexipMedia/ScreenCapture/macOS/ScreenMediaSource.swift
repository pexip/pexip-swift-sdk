#if os(macOS)

import CoreGraphics
import CoreMedia
import ScreenCaptureKit

/// A source of the screen content for media capture.
public enum ScreenMediaSource: Equatable {
    public static func == (lhs: ScreenMediaSource, rhs: ScreenMediaSource) -> Bool {
        switch (lhs, rhs) {
        case let (.display(d1), .display(d2)):
            return d1.displayID == d2.displayID
        case let (.window(w1), .window(w2)):
            return w1.windowID == w2.windowID
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
