#if os(macOS)

import CoreGraphics
import CoreMedia

/// A source of the screen content for video capture.
public enum ScreenVideoSource: Hashable {
    case display(Display)
    case window(Window)

    public var videoDimensions: CMVideoDimensions {
        switch self {
        case .display(let display):
            return CMVideoDimensions(
                width: Int32(display.width),
                height: Int32(display.height)
            )
        case .window(let window):
            return CMVideoDimensions(
                width: Int32(window.width),
                height: Int32(window.height)
            )
        }
    }

    /// Creates a new instance of ``ScreenVideoSourceEnumerator``
    public static func createEnumerator() -> ScreenVideoSourceEnumerator {
        if #available(macOS 12.3, *) {
            // Use ScreenCaptureKit
            // https://developer.apple.com/documentation/screencapturekit
            return NewScreenVideoSourceEnumerator()
        } else {
            // Use Quartz Window Services.
            // https://developer.apple.com/documentation/coregraphics/quartz_window_services
            return LegacyScreenVideoSourceEnumerator()
        }
    }

    /// Creates a new screen video capturer for the specified video source.
    public static func createCapturer(
        for videoSource: ScreenVideoSource
    ) -> ScreenVideoCapturer {
        if #available(macOS 12.3, *) {
            // Use ScreenCaptureKit
            // https://developer.apple.com/documentation/screencapturekit
            return NewScreenVideoCapturer(videoSource: videoSource)
        } else {
            // Use Quartz Window Services.
            // https://developer.apple.com/documentation/coregraphics/quartz_window_services
            switch videoSource {
            case .display(let display):
                return LegacyDisplayVideoCapturer(display: display)
            case .window(let window):
                return LegacyWindowVideoCapturer(window: window)
            }
        }
    }
}

#endif
