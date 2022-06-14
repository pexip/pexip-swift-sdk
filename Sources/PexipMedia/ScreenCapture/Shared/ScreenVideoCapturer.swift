import CoreVideo
import Combine
import CoreMedia

// MARK: - ScreenVideoCapturerDelegate

public protocol ScreenVideoCapturerDelegate: AnyObject {
    func screenVideoCapturer(
        _ capturer: ScreenVideoCapturer,
        didCaptureVideoFrame frame: VideoFrame
    )

    func screenVideoCapturer(
        _ capturer: ScreenVideoCapturer,
        didStopWithError error: Error?
    )
}

// MARK: - ScreenVideoCapturer

/// A video capturer that captures the screen content as a video stream.
public protocol ScreenVideoCapturer: AnyObject {
    var delegate: ScreenVideoCapturerDelegate? { get set }

    /**
     Starts screen capture.
     - Parameters:
        - fps: The desired minimum fps between frame updates.
     */
    func startCapture(withFps fps: UInt) async throws

    /// Stops screen capture
    func stopCapture() async throws
}
