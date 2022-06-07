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
        case stopped
    }

    /// The pixel buffer.
    public let pixelBuffer: CVPixelBuffer

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

    // The dimensions of the pixel buffer
    public var dimensions: CMVideoDimensions {
        CMVideoDimensions(width: Int32(width), height: Int32(height))
    }
}
