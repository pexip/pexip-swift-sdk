#if os(macOS)

import AppKit
import Combine
import CoreMedia

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
    let videoSource: ScreenVideoSource
    weak var delegate: ScreenVideoCapturerDelegate?

    private var isCapturing = false
    private var stream: SCStream?
    private var startTimeNs: UInt64?
    private let dispatchQueue = DispatchQueue(
        label: "com.pexip.PexipMedia.NewScreenVideoCapturer",
        qos: .userInteractive
    )

    // MARK: - Init

    init(videoSource: ScreenVideoSource) {
        self.videoSource = videoSource
    }

    deinit {
        try? stream?.removeStreamOutput(self, type: .screen)
        stream?.stopCapture(completionHandler: { _ in })
    }

    // MARK: - ScreenVideoCapturer

    func startCapture(withFps fps: UInt) async throws {
        let content = try await SCShareableContent.defaultSelection()
        var filter: SCContentFilter?

        switch videoSource {
        case .display(let display):
            filter = content.displays
                .first(where: {
                    $0.displayID == display.displayID
                }).map({
                    SCContentFilter(
                        display: $0,
                        excludingApplications: [],
                        exceptingWindows: []
                    )
                })
        case .window(let window):
            filter = content.windows
                .first(where: {
                    $0.windowID == window.windowID
                }).map({
                    SCContentFilter(desktopIndependentWindow: $0)
                })
        }

        if let filter = filter {
            try await startCapture(filter: filter, fps: fps)
        } else {
            throw ScreenCaptureError.noScreenVideoSourceAvailable
        }
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
                delegate?.screenVideoCapturer(self, didStopWithError: nil)
            }
        case .complete:
            if let pixelBuffer = sampleBuffer.imageBuffer {
                let videoFrame = VideoFrame(
                    pixelBuffer: pixelBuffer,
                    displayTimeNs: displayTimeNs,
                    elapsedTimeNs: displayTimeNs - startTimeNs!
                )
                delegate?.screenVideoCapturer(self, didCaptureVideoFrame: videoFrame)
            }
        @unknown default:
            break
        }
    }

    // MARK: - Private

    private func startCapture(
        filter: SCContentFilter,
        fps: UInt
    ) async throws {
        try await stopCapture()

        let streamConfig = SCStreamConfiguration()
        streamConfig.minimumFrameInterval = CMTime(fps: fps)
        streamConfig.width = Int(videoSource.videoDimensions.width)
        streamConfig.height = Int(videoSource.videoDimensions.height)

        stream = SCStream(filter: filter, configuration: streamConfig, delegate: nil)
        try stream?.addStreamOutput(self, type: .screen, sampleHandlerQueue: dispatchQueue)
        try await stream?.startCapture()
        isCapturing = true
    }
}

#endif
