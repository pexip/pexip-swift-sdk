import CoreVideo
import Combine
import CoreMedia

// MARK: - ScreenMediaCapturerDelegate

public protocol ScreenMediaCapturerDelegate: AnyObject {
    func screenMediaCapturer(
        _ capturer: ScreenMediaCapturer,
        didCaptureVideoFrame frame: VideoFrame
    )

    func screenMediaCapturer(
        _ capturer: ScreenMediaCapturer,
        didStopWithError error: Error?
    )
}

// MARK: - ScreenMediaCapturer

/// A capturer that captures the screen content.
public protocol ScreenMediaCapturer: AnyObject {
    var delegate: ScreenMediaCapturerDelegate? { get set }

    /**
     Starts screen capture with the given video quality profile.
     - Parameters:
        - videoProfile: The video quality profile.
     */
    func startCapture(withVideoProfile videoProfile: QualityProfile) async throws

    /// Stops screen capture
    func stopCapture() async throws
}
