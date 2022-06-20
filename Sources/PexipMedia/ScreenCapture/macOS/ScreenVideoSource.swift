#if os(macOS)

import CoreGraphics
import CoreMedia
import ScreenCaptureKit

/// A source of the screen content for video capture.
public enum ScreenVideoSource: Equatable {
    public static func == (lhs: ScreenVideoSource, rhs: ScreenVideoSource) -> Bool {
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

    /// The video dimensions on the sceen content.
    public var videoDimensions: CMVideoDimensions {
        switch self {
        case .display(let display):
            return display.videoDimensions
        case .window(let window):
            return window.videoDimensions
        }
    }

    /// Creates a new instance of ``ScreenVideoSourceEnumerator``
    public static func createEnumerator() -> ScreenVideoSourceEnumerator {
        if #available(macOS 12.3, *) {
            // Use ScreenCaptureKit
            // https://developer.apple.com/documentation/screencapturekit
            return NewScreenVideoSourceEnumerator<SCShareableContent>()
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
            return NewScreenVideoCapturer(
                videoSource: videoSource,
                streamFactory: SCStreamFactory()
            )
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
