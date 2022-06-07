#if os(macOS)

import CoreVideo
import Combine

// MARK: - ScreenVideoCapturerDelegate

public protocol ScreenVideoCapturerDelegate: AnyObject {
    func screenVideoCapturer(
        _ capturer: ScreenVideoCapturer,
        didCaptureVideoFrame frame: VideoFrame
    )

    func screenVideoCapturerDidStop(_ capturer: ScreenVideoCapturer)
}

/// A video capturer that captures the screen content as a video stream.
public protocol ScreenVideoCapturer: AnyObject {
    var delegate: ScreenVideoCapturerDelegate? { get set }
    var publisher: AnyPublisher<VideoFrame.Status, Never> { get }

    func startCapture(
        videoSource: ScreenVideoSource,
        configuration: ScreenCaptureConfiguration
    ) async throws

    func startCapture(
        display: Display,
        configuration: ScreenCaptureConfiguration
    ) async throws

    func startCapture(
        window: Window,
        configuration: ScreenCaptureConfiguration
    ) async throws

    func stopCapture() async throws
}

// MARK: - Default implementations

public extension ScreenVideoCapturer {
    func startCapture(
        videoSource: ScreenVideoSource,
        configuration: ScreenCaptureConfiguration
    ) async throws {
        switch videoSource {
        case .display(let display):
            try await startCapture(display: display, configuration: configuration)
        case .window(let window):
            try await startCapture(window: window, configuration: configuration)
        }
    }
}

#endif
