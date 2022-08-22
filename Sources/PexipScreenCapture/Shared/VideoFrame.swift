import CoreVideo
import ImageIO
import CoreMedia
import CoreImage

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

    /// The x position of the video content, in pixels
    public var contentX: Int32 {
        Int32(contentRect.origin.x.rounded(.down))
    }

    /// The y position of the video content, in pixels
    public var contentY: Int32 {
        Int32(contentRect.origin.y.rounded(.down))
    }

    // MARK: - Init

    /**
     Creates a new instance of ``VideoFrame``.

     - Parameters:
        - pixelBuffer: The pixel buffer
        - contentRect: The size and location of the video content, in pixels
        - orientation: The intended display orientation for an image
        - displayTimeNs: The timestamp of when the frame was displayed (in nanoseconds)
     */
    public init(
        pixelBuffer: CVPixelBuffer,
        contentRect: CGRect? = nil,
        orientation: CGImagePropertyOrientation = .up,
        displayTimeNs: UInt64
    ) {
        self.pixelBuffer = pixelBuffer
        self.contentRect = contentRect ?? CGRect(
            x: 0,
            y: 0,
            width: Int(pixelBuffer.width),
            height: Int(pixelBuffer.height)
        )
        self.orientation = orientation
        self.displayTimeNs = displayTimeNs
    }

    // MARK: - Public functions

    /**
     Returns new content dimensions with the same aspect ratio as the original,
     but adapted to the given video quality profile.

     - Parameters:
        - outputDimensions: The dimensions of the output video.
     - Returns: New content dimensions adapted to the given video quality profile.
     */
    public func adaptedContentDimensions(
        to outputDimensions: CMVideoDimensions
    ) -> CMVideoDimensions {
        let from = contentDimensions
        let to = outputDimensions

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
}
