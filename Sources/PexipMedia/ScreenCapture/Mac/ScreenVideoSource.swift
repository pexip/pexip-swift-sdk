#if os(macOS)

/// A source of the screen content for video capture.
public enum ScreenVideoSource: Hashable {
    case display(Display)
    case window(Window)

    /// Creates 
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

    public static func createCapturer() -> ScreenVideoCapturer {
        if #available(macOS 12.3, *) {
            // Use ScreenCaptureKit
            // https://developer.apple.com/documentation/screencapturekit
            return NewScreenVideoCapturer()
        } else {
            // Use Quartz Window Services.
            // https://developer.apple.com/documentation/coregraphics/quartz_window_services
            return LegacyScreenVideoCapturer()
        }
    }
}

#endif
