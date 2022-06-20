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
final class NewScreenVideoCapturer<Factory: ScreenCaptureStreamFactory>:
    NSObject,
    ScreenVideoCapturer,
    SCStreamOutput,
    SCStreamDelegate
{
    let videoSource: ScreenVideoSource
    weak var delegate: ScreenVideoCapturerDelegate?
    private(set) var isCapturing = false

    private let streamFactory: Factory
    private var stream: SCStream?
    private var startTimeNs: UInt64?
    private let dispatchQueue = DispatchQueue(
        label: "com.pexip.PexipMedia.NewScreenVideoCapturer",
        qos: .userInteractive
    )

    // MARK: - Init

    init(videoSource: ScreenVideoSource, streamFactory: Factory) {
        self.videoSource = videoSource
        self.streamFactory = streamFactory
    }

    deinit {
        try? stream?.removeStreamOutput(self, type: .screen)
        stream?.stopCapture(completionHandler: { _ in })
    }

    // MARK: - ScreenVideoCapturer

    func startCapture(withFps fps: UInt) async throws {
        try await stopCapture()

        let videoDimensions = videoSource.videoDimensions
        let streamConfig = SCStreamConfiguration()
        streamConfig.minimumFrameInterval = CMTime(fps: fps)
        streamConfig.width = Int(videoDimensions.width)
        streamConfig.height = Int(videoDimensions.height)

        stream = try await streamFactory.createStream(
            videoSource: videoSource,
            configuration: streamConfig,
            delegate: nil
        )

        try stream?.addStreamOutput(self, type: .screen, sampleHandlerQueue: dispatchQueue)
        try await stream?.startCapture()
        isCapturing = true
    }

    func stopCapture() async throws {
        isCapturing = false
        startTimeNs = nil
        try stream?.removeStreamOutput(self, type: .screen)
        try await stream?.stopCapture()
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
            createIfNecessary: false
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

        let displayTimeNs = MachAbsoluteTime(displayTime).nanoseconds
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
}

#endif
