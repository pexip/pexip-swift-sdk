#if os(macOS)

import AppKit
import CoreMedia
import Combine

/**
 Quartz Window Services -based window media capturer.
 https://developer.apple.com/documentation/coregraphics/quartz_window_services
 */
final class LegacyWindowCapturer: ScreenMediaCapturer {
    weak var delegate: ScreenMediaCapturerDelegate?
    let window: Window
    private(set) var isCapturing = false
    var displayTimeNs: () -> UInt64 = {
        clock_gettime_nsec_np(CLOCK_UPTIME_RAW)
    }

    private var timer: DispatchSourceTimer?
    private let processingQueue = DispatchQueue(
        label: "com.pexip.PexipScreenCapture.LegacyWindowMediaCapturer",
        qos: .userInteractive
    )
    private let ciContext = CIContext()

    // MARK: - Init

    init(window: Window) {
        self.window = window
    }

    deinit {
        try? stopCapture()
    }

    // MARK: - Capture

    func startCapture(
        atFps fps: UInt,
        outputDimensions: CMVideoDimensions
    ) async throws {
        try stopCapture()

        let timeIntervalNs = CMTime(fps: fps).seconds * 1_000_000_000

        timer = DispatchSource.makeTimerSource(flags: .strict, queue: processingQueue)
        timer?.setEventHandler(handler: { [weak self] in
            self?.captureImage()
        })
        timer?.schedule(
            deadline: .now(),
            repeating: .nanoseconds(Int(timeIntervalNs))
        )
        timer?.activate()

        isCapturing = true
    }

    func stopCapture() throws {
        timer?.cancel()
        timer = nil
        isCapturing = false
    }

    // MARK: - Private

    private func captureImage() {
        guard let cgImage = window.createImage() else {
            return
        }

        var pixelBuffer: CVPixelBuffer?

        CVPixelBufferCreate(
            kCFAllocatorDefault,
            cgImage.width,
            cgImage.height,
            kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
            nil,
            &pixelBuffer
        )

        guard let pixelBuffer else {
            return
        }

        pixelBuffer.lockBaseAddress(.init(rawValue: 0))

        let ciImage = CIImage(cgImage: cgImage)
        ciContext.render(ciImage, to: pixelBuffer)

        pixelBuffer.unlockBaseAddress(.init(rawValue: 0))

        let displayTimeNs = self.displayTimeNs()

        let videoFrame = VideoFrame(
            pixelBuffer: pixelBuffer,
            contentRect: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height),
            displayTimeNs: displayTimeNs
        )

        delegate?.screenMediaCapturer(self, didCaptureVideoFrame: videoFrame)
    }
}

#endif
