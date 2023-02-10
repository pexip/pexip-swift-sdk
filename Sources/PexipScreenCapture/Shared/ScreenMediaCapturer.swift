import CoreVideo
import Combine
import CoreMedia

// MARK: - ScreenMediaCapturerDelegate

public protocol ScreenMediaCapturerDelegate: AnyObject {
    func screenMediaCapturer(
        _ capturer: ScreenMediaCapturer,
        didCaptureVideoFrame frame: VideoFrame
    )

    #if os(iOS)

    func screenMediaCapturerDidStart(_ capturer: ScreenMediaCapturer)

    #endif

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
        - fps: The FPS of a video stream (1...60)
        - outputDimensions: The dimensions of the output video.
     */
    func startCapture(
        atFps fps: UInt,
        outputDimensions: CMVideoDimensions
    ) async throws

    /// Stops screen capture
    func stopCapture() async throws

    /**
     Stops screen capture with the given reason.

     - Parameters:
        - reason: An optional reason why screen capture was stopped.
     */
    func stopCapture(reason: ScreenCaptureStopReason?) async throws
}

#if os(macOS)

public extension ScreenMediaCapturer {
    func stopCapture(reason: ScreenCaptureStopReason?) async throws {
        // Stop reason is not so important on macOS,
        // but it's possible to override this method in your own custom implementation
        // of `ScreenMediaCapturer` if needed.
        try await stopCapture()
    }
}

#endif

// MARK: - ScreenCaptureStopReason

public enum ScreenCaptureStopReason: Int {
    case presentationStolen
    case callEnded
}
