import CoreVideo
import ImageIO
import CoreMedia

/// An object that represents a video frame.
public struct VideoFrame {
    /// The capture status
    public enum Status {
        /// New frame was generated.
        case complete(VideoFrame)
        /// The stream was stopped.
        case stopped(error: Error?)
    }

    /// The pixel buffer.
    public let pixelBuffer: CVPixelBuffer

    /// The size and location of the video content, in pixels.
    public let contentRect: CGRect

    /// The intended display orientation for an image.
    public var orientation: CGImagePropertyOrientation = .up

    /// The timestamp of when the corresponding frame was displayed (in nanoseconds).
    public let displayTimeNs: UInt64

    /// The elapsed time since the start of video capture (in nanoseconds).
    public let elapsedTimeNs: UInt64

    /// The width of the pixel buffer
    public var width: UInt32 {
        pixelBuffer.width
    }

    /// The height of the pixel buffer
    public var height: UInt32 {
        pixelBuffer.height
    }

    /// The dimensions of the pixel buffer, in pixels.
    public var pixelBufferDimensions: CMVideoDimensions {
        CMVideoDimensions(width: Int32(width), height: Int32(height))
    }

    /// The dimensions of the video content, in pixels
    public var contentDimensions: CMVideoDimensions {
        CMVideoDimensions(
            width: Int32(contentRect.width.rounded(.down)),
            height: Int32(contentRect.height.rounded(.down))
        )
    }

    /**
     Returns new content dimensions with the same aspect ratio as the original,
     but adapted to the given video quality profile.

     - Parameters:
        - qualityProfile: The video quality profile.
     - Returns: New content dimensions adapted to the given video quality profile.
     */
    public func adaptedContentDimensions(
        to qualityProfile: QualityProfile
    ) -> CMVideoDimensions {
        let from = contentDimensions
        let to = qualityProfile.dimensions

        if from.height > to.height {
            let ratio = Float(from.height) / Float(from.width)
            let newHeight = to.height
            let newWidth = Int32((Float(newHeight) / ratio).rounded(.down))
            return CMVideoDimensions(width: newWidth, height: newHeight)
        } else if from.width > to.width {
            let ratio = Float(from.height) / Float(from.width)
            let newWidth = to.width
            let newHeight = Int32((Float(newWidth) * ratio).rounded(.down))
            return CMVideoDimensions(width: newWidth, height: newHeight)
        }

        return from
    }

    /// The x position of the video content, in pixels
    public var contentX: Int32 {
        Int32(contentRect.origin.x.rounded(.down))
    }

    /// The y position of the video content, in pixels
    public var contentY: Int32 {
        Int32(contentRect.origin.y.rounded(.down))
    }
}
