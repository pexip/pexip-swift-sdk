#if os(macOS)

import CoreGraphics

#if canImport(ScreenCaptureKit)
import ScreenCaptureKit
#endif

/// An object that represents a display device.
public struct Display: Hashable {
    /// The Core Graphics display identifier.
    public let displayID: CGDirectDisplayID
    /// The width of the display in points.
    public let width: Int
    /// The height of the display in points.
    public let height: Int
    /// Optional preview image, use ``createImage()`` to create a new one.
    public var previewImage: CGImage?
    /// The aspect ratio of the display
    public var aspectRatio: CGFloat {
        CGFloat(width) / CGFloat(height)
    }

    /// Returns an image containing the contents of the display.
    public func createImage() -> CGImage? {
        CGDisplayCreateImage(displayID)
    }

    // MARK: - Init

    /**
     Creates a new object that represents a display device.
     - Parameters:
        - displayID: The Core Graphics display identifier.
        - width: The width of the display in points.
        - height: The height of the display in points.
        - previewImage: Optional preview image, use ``createImage()`` to create a new one.
     */
    public init(
        displayID: CGDirectDisplayID,
        width: Int,
        height: Int,
        previewImage: CGImage? = nil
    ) {
        self.displayID = displayID
        self.width = width
        self.height = height
        self.previewImage = previewImage
    }

    @available(macOS 12.3, *)
    init(scDisplay: SCDisplay) {
        self.displayID = scDisplay.displayID
        self.width = scDisplay.width
        self.height = scDisplay.height
    }

    init?(displayID: CGDirectDisplayID) {
        guard let displayMode = CGDisplayCopyDisplayMode(displayID) else {
            return nil
        }

        self.displayID = displayID
        self.width = displayMode.width
        self.height = displayMode.height
    }
}

#endif
