import CoreVideo

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
    /// The timestamp of when the corresponding frame was displayed (in nanoseconds).
    public let displayTimeNs: UInt64
    /// The elapsed time since the start of video capture (in nanoseconds).
    public let elapsedTimeNs: UInt64
}
