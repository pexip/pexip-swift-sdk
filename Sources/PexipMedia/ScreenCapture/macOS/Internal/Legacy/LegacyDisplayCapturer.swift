#if os(macOS)

import AppKit
import CoreMedia
import Combine

/**
 Quartz Window Services -based display media capturer.
 https://developer.apple.com/documentation/coregraphics/quartz_window_services
 */
final class LegacyDisplayCapturer: ScreenMediaCapturer {
    let display: Display
    let displayStreamType: LegacyDisplayStream.Type
    weak var delegate: ScreenMediaCapturerDelegate?
    private(set) var isCapturing = false

    private var displayStream: LegacyDisplayStream?
    private var startTimeNs: UInt64?
    private let processingQueue = DispatchQueue(
        label: "com.pexip.PexipMedia.LegacyDisplayCapturer",
        qos: .userInteractive
    )

    // MARK: - Init

    init(
        display: Display,
        displayStreamType: LegacyDisplayStream.Type = CGDisplayStream.self
    ) {
        self.display = display
        self.displayStreamType = displayStreamType
    }

    deinit {
        try? stopCapture()
    }

    // MARK: - ScreenMediaCapturer

    func startCapture(withVideoProfile videoProfile: QualityProfile) async throws {
        try stopCapture()

        let properties: [CFString: Any] = [
            CGDisplayStream.preserveAspectRatio: kCFBooleanTrue as Any,
            CGDisplayStream.minimumFrameTime: CMTime(
                fps: videoProfile.fps
            ).seconds as CFNumber
        ]

        displayStream = displayStreamType.init(
            dispatchQueueDisplay: display.displayID,
            outputWidth: Int(videoProfile.width),
            outputHeight: Int(videoProfile.height),
            pixelFormat: Int32(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange),
            properties: properties as CFDictionary,
            queue: processingQueue,
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
        let displayTimeNs = MachAbsoluteTime(displayTime).nanoseconds
        startTimeNs = startTimeNs ?? displayTimeNs

        switch status {
        case .frameIdle, .frameBlank:
            break
        case .stopped:
            if isCapturing {
                isCapturing = false
                delegate?.screenMediaCapturer(self, didStopWithError: nil)
            }
        case .frameComplete:
            guard let ioSurface = ioSurface else {
                break
            }

            var pixelBufferRef: Unmanaged<CVPixelBuffer>?
            let attributes: [AnyHashable: Any] = [
                kCVPixelBufferIOSurfacePropertiesKey: true as AnyObject
            ]

            let result = CVPixelBufferCreateWithIOSurface(
                kCFAllocatorDefault, ioSurface,
                attributes as CFDictionary,
                &pixelBufferRef
            )

            if let pixelBufferRef = pixelBufferRef, result == kCVReturnSuccess {
                let pixelBuffer = pixelBufferRef.takeRetainedValue()
                let videoFrame = VideoFrame(
                    pixelBuffer: pixelBuffer,
                    contentRect: CGRect(
                        x: 0,
                        y: 0,
                        width: Int(pixelBuffer.width),
                        height: Int(pixelBuffer.height)
                    ),
                    displayTimeNs: displayTimeNs,
                    elapsedTimeNs: displayTimeNs - startTimeNs!
                )
                delegate?.screenMediaCapturer(self, didCaptureVideoFrame: videoFrame)
            }
        @unknown default:
            break
        }
    }
}

#endif
