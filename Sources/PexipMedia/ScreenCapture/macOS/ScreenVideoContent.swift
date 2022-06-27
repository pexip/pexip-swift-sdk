#if os(macOS)

import CoreGraphics
import CoreMedia

/// An object that represents a screen video content your app can capture.
public protocol ScreenVideoContent {
    /// The width of the screen content in points.
    var width: Int { get }

    /// The height of the screen content in points.
    var height: Int { get }

    /// Returns an image containing the captured content of the screen.
    func createImage() -> CGImage?
}

// MARK: - Default implementations

public extension ScreenVideoContent {
    /// The aspect ratio of the screen content.
    var aspectRatio: CGFloat {
        CGFloat(width) / CGFloat(height)
    }

    /// The video dimensions on the sceen content.
    var videoDimensions: CMVideoDimensions {
        CMVideoDimensions(
            width: Int32(width),
            height: Int32(height)
        )
    }
}

#endif
