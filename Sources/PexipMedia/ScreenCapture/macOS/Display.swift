#if os(macOS)

import CoreGraphics

/// An object that represents a display device.
public protocol Display: ScreenVideoContent {
    /// The Core Graphics display identifier.
    var displayID: CGDirectDisplayID { get }

    /// The width of the display in points.
    var width: Int { get }

    /// The height of the display in points.
    var height: Int { get }
}

// MARK: - Default implementations

public extension Display {
    /// Returns an image containing the contents of the display.
    func createImage() -> CGImage? {
        CGDisplayCreateImage(displayID)
    }
}

#endif
