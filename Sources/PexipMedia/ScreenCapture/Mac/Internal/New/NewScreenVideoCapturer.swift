#if os(macOS)

import AppKit
import Combine

#if canImport(ScreenCaptureKit)
import ScreenCaptureKit
#endif

/**
 ScreenCaptureKit -based screen video capturer.
 https://developer.apple.com/documentation/screencapturekit
 */
@available(macOS 12.3, *)
final class NewScreenVideoCapturer: NSObject,
                                    ScreenVideoCapturer,
                                    SCStreamOutput,
                                    SCStreamDelegate {
    weak var delegate: ScreenVideoCapturerDelegate?
    var publisher: AnyPublisher<VideoFrame.Status, Never> {
        subject.eraseToAnyPublisher()
    }

    private var isCapturing = false
    private var stream: SCStream?
    private var startTimeNs: UInt64?
    private let subject = PassthroughSubject<VideoFrame.Status, Never>()
    private let dispatchQueue = DispatchQueue(
        label: "com.pexip.PexipMedia.NewScreenVideoCapturer",
        qos: .userInteractive
    )

    deinit {
        try? stream?.removeStreamOutput(self, type: .screen)
        stream?.stopCapture(completionHandler: { _ in })
    }

    // MARK: - ScreenVideoCapturer

    func startCapture(
        display: Display,
        configuration: ScreenCaptureConfiguration
    ) async throws {
        let content = try await SCShareableContent.defaultSelection()

        guard let display = content.displays.first(where: {
            $0.displayID == display.displayID
        }) else {
            return
        }

        let filter = SCContentFilter(
            display: display,
            excludingApplications: [],
            exceptingWindows: []
        )

        try await startCapture(filter: filter, configuration: configuration)
    }

    func startCapture(
        window: Window,
        configuration: ScreenCaptureConfiguration
    ) async throws {
        let content = try await SCShareableContent.defaultSelection()

        guard let window = content.windows.first(where: {
            $0.windowID == window.windowID
        }) else {
            return
        }

        let filter = SCContentFilter(desktopIndependentWindow: window)
        try await startCapture(filter: filter, configuration: configuration)
    }

    func stopCapture() async throws {
        isCapturing = false
        startTimeNs = nil
        try await stream?.stopCapture()
        try stream?.removeStreamOutput(self, type: .screen)
        stream = nil
    }

    // MARK: - SCStreamOutput

    func stream(
        _ stream: SCStream,
        didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
        of type: SCStreamOutputType
    ) {
        guard let attachments = (CMSampleBufferGetSampleAttachmentsArray(
            sampleBuffer,
            createIfNecessary: true
        ) as? [[SCStreamFrameInfo: Any]])?.first else {
            return
        }

        guard let statusRawValue = attachments[.status] as? Int,
              let status = SCFrameStatus(rawValue: statusRawValue)
        else {
            return
        }

        guard let displayTime = attachments[.displayTime] as? UInt64 else {
            return
        }

        let displayTimeNs = displayTime.nanoseconds
        startTimeNs = startTimeNs ?? displayTimeNs

        switch status {
        case .idle, .blank, .suspended, .started:
            break
        case .stopped:
            if isCapturing {
                isCapturing = false
                onStop()
            }
        case .complete:
            if let pixelBuffer = sampleBuffer.imageBuffer {
                onCapture(videoFrame: VideoFrame(
                    pixelBuffer: pixelBuffer,
                    displayTimeNs: displayTimeNs,
                    elapsedTimeNs: displayTimeNs - startTimeNs!
                ))
            }
        @unknown default:
            break
        }
    }

    // MARK: - Private

    private func startCapture(
        filter: SCContentFilter,
        configuration: ScreenCaptureConfiguration
    ) async throws {
        try await stopCapture()

        let streamConfig = SCStreamConfiguration()
        streamConfig.minimumFrameInterval = configuration.minimumFrameInterval
        streamConfig.queueDepth = configuration.queueDepth
        streamConfig.width = configuration.width
        streamConfig.height = configuration.height
        streamConfig.scalesToFit = configuration.scalesToFit

        stream = SCStream(filter: filter, configuration: streamConfig, delegate: nil)
        try stream?.addStreamOutput(self, type: .screen, sampleHandlerQueue: dispatchQueue)
        try await stream?.startCapture()
        isCapturing = true
    }

    private func onStop() {
        delegate?.screenVideoCapturerDidStop(self)
        subject.send(.stopped)
    }

    private func onCapture(videoFrame: VideoFrame) {
        delegate?.screenVideoCapturer(self, didCaptureVideoFrame: videoFrame)
        subject.send(.complete(videoFrame))
    }

    private func getShareableContent() async throws -> SCShareableContent {
        try await SCShareableContent.excludingDesktopWindows(
            true,
            onScreenWindowsOnly: true
        )
    }
}

#endif
