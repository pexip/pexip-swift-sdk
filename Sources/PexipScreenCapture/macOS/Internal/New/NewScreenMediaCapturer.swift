#if os(macOS)

import AppKit
import Combine
import CoreMedia

#if canImport(ScreenCaptureKit)
import ScreenCaptureKit
#endif

/**
 ScreenCaptureKit -based screen media capturer.
 https://developer.apple.com/documentation/screencapturekit
 */
@available(macOS 12.3, *)
final class NewScreenMediaCapturer<Factory: ScreenCaptureStreamFactory>: NSObject,
    ScreenMediaCapturer,
    SCStreamOutput,
    SCStreamDelegate
{
    let source: ScreenMediaSource
    weak var delegate: ScreenMediaCapturerDelegate?
    private(set) var isCapturing = false

    private let streamFactory: Factory
    private var stream: SCStream?
    private let dispatchQueue = DispatchQueue(
        label: "com.pexip.PexipMedia.NewScreenMediaCapturer",
        qos: .userInteractive
    )

    // MARK: - Init

    init(source: ScreenMediaSource, streamFactory: Factory) {
        self.source = source
        self.streamFactory = streamFactory
    }

    deinit {
        try? stream?.removeStreamOutput(self, type: .screen)
        stream?.stopCapture(completionHandler: { _ in })
    }

    // MARK: - ScreenMediaCapturer

    func startCapture(
        atFps fps: UInt,
        outputDimensions: CMVideoDimensions
    ) async throws {
        try await stopCapture()

        let streamConfig = SCStreamConfiguration()
        streamConfig.backgroundColor = .black
        streamConfig.pixelFormat = kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
        streamConfig.minimumFrameInterval = CMTime(fps: fps)
        streamConfig.width = Int(outputDimensions.width)
        streamConfig.height = Int(outputDimensions.height)

        stream = try await streamFactory.createStream(
            mediaSource: source,
            configuration: streamConfig,
            delegate: nil
        )

        try stream?.addStreamOutput(self, type: .screen, sampleHandlerQueue: dispatchQueue)
        try await stream?.startCapture()
        isCapturing = true
    }

    func stopCapture() async throws {
        isCapturing = false
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

        // Retrieve the content rectangle, scale, and scale factor.
        // swiftlint:disable force_cast
        guard let contentRectDict = attachments[.contentRect],
              var contentRect = CGRect(dictionaryRepresentation: contentRectDict as! CFDictionary),
              let scaleFactor = attachments[.scaleFactor] as? CGFloat
        else {
            return
        }

        let transform = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
        contentRect = contentRect.applying(transform)

        let displayTimeNs = MachAbsoluteTime(displayTime).nanoseconds

        switch status {
        case .idle, .blank, .suspended, .started:
            break
        case .stopped:
            if isCapturing {
                isCapturing = false
                delegate?.screenMediaCapturer(self, didStopWithError: nil)
            }
        case .complete:
            if let pixelBuffer = sampleBuffer.imageBuffer {
                let videoFrame = VideoFrame(
                    pixelBuffer: pixelBuffer,
                    contentRect: contentRect,
                    displayTimeNs: displayTimeNs
                )
                delegate?.screenMediaCapturer(self, didCaptureVideoFrame: videoFrame)
            }
        @unknown default:
            break
        }
    }
}

#endif
