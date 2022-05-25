#if os(macOS)

import AppKit
import CoreMedia

// MARK: - LegacyDisplayCapturerDelegate

protocol LegacyDisplayVideoCapturerDelegate: AnyObject {
    func legacyDisplayVideoCapturer(
        _ capturer: LegacyDisplayVideoCapturer,
        didCaptureVideoFrame videoFrame: VideoFrame
    )

    func legacyDisplayVideoCapturerDidStop(_ capturer: LegacyDisplayVideoCapturer)
}

// MARK: - LegacyDisplayCapturer

/**
 Quartz Window Services -based display video capturer.
 https://developer.apple.com/documentation/coregraphics/quartz_window_services
 */
final class LegacyDisplayVideoCapturer {
    weak var delegate: LegacyDisplayVideoCapturerDelegate?

    private var isCapturing = false
    private var displayStream: CGDisplayStream?
    private var startTimeNs: UInt64?
    private let dispatchQueue = DispatchQueue(
        label: "com.pexip.PexipMedia.LegacyDisplayVideoCapturer",
        qos: .userInteractive
    )

    deinit {
        try? stopCapture()
    }

    // MARK: - Capture

    func startCapture(
        display: Display,
        configuration: ScreenCaptureConfiguration
    ) throws {
        try stopCapture()

        let minimumFrameRate = configuration.minimumFrameIntervalSeconds as CFNumber

        let properties: [CFString: Any] = [
            CGDisplayStream.preserveAspectRatio: configuration.scalesToFit
                ? kCFBooleanFalse as Any
                : kCFBooleanTrue as Any,
            CGDisplayStream.queueDepth: configuration.queueDepth as CFNumber,
            CGDisplayStream.minimumFrameTime: minimumFrameRate
        ]

        displayStream = CGDisplayStream(
            dispatchQueueDisplay: display.displayID,
            outputWidth: configuration.width,
            outputHeight: configuration.height,
            pixelFormat: Int32(k32BGRAPixelFormat),
            properties: properties as CFDictionary,
            queue: dispatchQueue,
            handler: { [weak self] status, displayTime, ioSurface, _ in
                self?.handleDisplayStream(
                    status: status,
                    displayTime: displayTime,
                    ioSurface: ioSurface
                )
            }
        )

        let result = displayStream!.start()

        if result == .success {
            isCapturing = true
        } else {
            displayStream = nil
            throw ScreenCaptureError.cgError(result)
        }
    }

    func stopCapture() throws {
        defer {
            displayStream = nil
        }

        startTimeNs = nil
        isCapturing = false

        if let result = displayStream?.stop(), result != .success {
            throw ScreenCaptureError.cgError(result)
        }
    }

    // MARK: - Private

    private func handleDisplayStream(
        status: CGDisplayStreamFrameStatus,
        displayTime: UInt64,
        ioSurface: IOSurfaceRef?
    ) {
        let displayTimeNs = displayTime.nanoseconds
        startTimeNs = startTimeNs ?? displayTimeNs

        switch status {
        case .frameIdle, .frameBlank:
            break
        case .stopped:
            if isCapturing {
                isCapturing = false
                delegate?.legacyDisplayVideoCapturerDidStop(self)
            }
        case .frameComplete:
            guard let ioSurface = ioSurface else {
                break
            }

            var pixelBuffer: Unmanaged<CVPixelBuffer>?
            let attributes: [AnyHashable: Any] = [
                kCVPixelBufferIOSurfacePropertiesKey : true as AnyObject
            ]

            let result = CVPixelBufferCreateWithIOSurface(
                kCFAllocatorDefault, ioSurface,
                attributes as CFDictionary,
                &pixelBuffer
            )

            if let pixelBuffer = pixelBuffer, result == kCVReturnSuccess {
                let videoFrame = VideoFrame(
                    pixelBuffer: pixelBuffer.takeRetainedValue(),
                    displayTimeNs: displayTimeNs,
                    elapsedTimeNs: displayTimeNs - startTimeNs!
                )
                delegate?.legacyDisplayVideoCapturer(self, didCaptureVideoFrame: videoFrame)
            }
        @unknown default:
            break
        }
    }
}

// MARK: - Global internal functions

#endif
