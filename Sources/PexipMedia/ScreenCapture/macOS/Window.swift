#if os(macOS)

import CoreGraphics

/// An object that represents an onscreen window.
public protocol Window: ScreenVideoContent {
    /// The Core Graphics window identifier.
    var windowID: CGWindowID { get }
    /// The string that displays in a window’s title bar.
    var title: String? { get }
    /// The app that owns the window.
    var application: RunningApplication? { get }
    /// The CGRect for the window
    var frame: CGRect { get }
    /// A Boolean value that indicates whether the window is on screen.
    var isOnScreen: Bool { get }
    /// The window layer of the window.
    var windowLayer: Int { get }
}

// MARK: - Default implementations

public extension Window {
    /// The width of the window in points.
    var width: Int {
        Int(frame.size.width)
    }

    /// The height of the window in points.
    var height: Int {
        Int(frame.size.height)
    }

    /// Returns an image containing the contents of the window.
    func createImage() -> CGImage? {
        CGWindowListCreateImage(
            .null,
            .optionIncludingWindow, windowID,
            [.boundsIgnoreFraming, .nominalResolution]
        )
    }
}

#endif
