#if os(macOS)

import AppKit
import Combine

/**
 Quartz Window Services -based screen video capturer.
 https://developer.apple.com/documentation/coregraphics/quartz_window_services
 */
final class LegacyScreenVideoCapturer: ScreenVideoCapturer,
                                       LegacyDisplayVideoCapturerDelegate,
                                       LegacyWindowVideoCapturerDelegate {
    weak var delegate: ScreenVideoCapturerDelegate?
    var publisher: AnyPublisher<VideoFrame.Status, Never> {
        subject.eraseToAnyPublisher()
    }

    private let subject = PassthroughSubject<VideoFrame.Status, Never>()
    private var displayCapturer: LegacyDisplayVideoCapturer?
    private var windowCapturer: LegacyWindowVideoCapturer?

    deinit {
        try? stopCapture()
    }

    // MARK: - ScreenVideoCapturer

    func startCapture(
        display: Display,
        configuration: ScreenCaptureConfiguration
    ) async throws {
        try stopCapture()

        displayCapturer = LegacyDisplayVideoCapturer()
        displayCapturer?.delegate = self

        try displayCapturer?.startCapture(
            display: display,
            configuration: configuration
        )
    }

    func startCapture(
        window: Window,
        configuration: ScreenCaptureConfiguration
    ) async throws {
        try stopCapture()

        windowCapturer = LegacyWindowVideoCapturer()
        windowCapturer?.delegate = self

        try windowCapturer?.startCapture(
            window: window,
            configuration: configuration
        )
    }

    func stopCapture() throws {
        try displayCapturer?.stopCapture()
        try windowCapturer?.stopCapture()

        displayCapturer = nil
        windowCapturer = nil
    }

    // MARK: - LegacyDisplayCapturerDelegate

    func legacyDisplayVideoCapturer(
        _ capturer: LegacyDisplayVideoCapturer,
        didCaptureVideoFrame videoFrame: VideoFrame
    ) {
        onCapture(videoFrame: videoFrame)
    }

    func legacyDisplayVideoCapturerDidStop(_ capturer: LegacyDisplayVideoCapturer) {
        onStop()
    }

    // MARK: - LegacyWindowCapturerDelegate

    func legacyWindowVideoCapturer(
        _ capturer: LegacyWindowVideoCapturer,
        didCaptureVideoFrame videoFrame: VideoFrame
    ) {
        onCapture(videoFrame: videoFrame)
    }

    // MARK: - Private

    private func onStop() {
        delegate?.screenVideoCapturerDidStop(self)
        subject.send(.stopped)
    }

    private func onCapture(videoFrame: VideoFrame) {
        delegate?.screenVideoCapturer(self, didCaptureVideoFrame: videoFrame)
        subject.send(.complete(videoFrame))
    }
}

#endif
