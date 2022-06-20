#if os(macOS)

import AppKit
import CoreMedia
import Combine

/**
 Quartz Window Services -based display video capturer.
 https://developer.apple.com/documentation/coregraphics/quartz_window_services
 */
final class LegacyDisplayVideoCapturer: ScreenVideoCapturer {
    let display: Display
    let displayStreamType: LegacyDisplayStream.Type
    weak var delegate: ScreenVideoCapturerDelegate?
    private(set) var isCapturing = false

    private var displayStream: LegacyDisplayStream?
    private var startTimeNs: UInt64?
    private let processingQueue = DispatchQueue(
        label: "com.pexip.PexipMedia.LegacyDisplayVideoCapturer",
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

    // MARK: - ScreenVideoCapturer

    func startCapture(withFps fps: UInt) async throws {
        try stopCapture()

        let properties: [CFString: Any] = [
            CGDisplayStream.preserveAspectRatio: kCFBooleanTrue as Any,
            CGDisplayStream.minimumFrameTime: CMTime(fps: fps).seconds as CFNumber
        ]

        displayStream = displayStreamType.init(
            dispatchQueueDisplay: display.displayID,
            outputWidth: Int(display.width),
            outputHeight: Int(display.height),
            pixelFormat: Int32(k32BGRAPixelFormat),
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
                delegate?.screenVideoCapturer(self, didStopWithError: nil)
            }
        case .frameComplete:
            guard let ioSurface = ioSurface else {
                break
            }

            var pixelBuffer: Unmanaged<CVPixelBuffer>?
            let attributes: [AnyHashable: Any] = [
                kCVPixelBufferIOSurfacePropertiesKey: true as AnyObject
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
                delegate?.screenVideoCapturer(self, didCaptureVideoFrame: videoFrame)
            }
        @unknown default:
            break
        }
    }
}

#endif
