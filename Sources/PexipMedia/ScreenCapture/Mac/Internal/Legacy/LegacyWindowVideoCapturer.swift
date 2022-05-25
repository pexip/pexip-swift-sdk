#if os(macOS)

import AppKit
import CoreMedia

// MARK: - LegacyWindowCapturerDelegate

protocol LegacyWindowVideoCapturerDelegate: AnyObject {
    func legacyWindowVideoCapturer(
        _ capturer: LegacyWindowVideoCapturer,
        didCaptureVideoFrame videoFrame: VideoFrame
    )
}

// MARK: - LegacyWindowCapturer

/**
 Quartz Window Services -based window video capturer.
 https://developer.apple.com/documentation/coregraphics/quartz_window_services
 */
final class LegacyWindowVideoCapturer {
    weak var delegate: LegacyWindowVideoCapturerDelegate?

    private var timer: Timer?
    private var frameCapturer: FrameCapturer?

    deinit {
        try? stopCapture()
    }

    // MARK: - Capture

    func startCapture(
        window: Window,
        configuration: ScreenCaptureConfiguration
    ) throws {
        try stopCapture()

        frameCapturer = FrameCapturer(
            window: window,
            queueDepth: configuration.queueDepth,
            delegate: self
        )

        DispatchQueue.main.async { [weak self] in
            self?.timer = Timer.scheduledTimer(
                withTimeInterval: configuration.minimumFrameIntervalSeconds,
                repeats: true,
                block: { _ in
                    Task { [weak self] in
                        await self?.frameCapturer?.captureFrame()
                    }
                })
        }
    }

    func stopCapture() throws {
        timer?.invalidate()
        timer = nil
        frameCapturer = nil
    }
}

// MARK: - FrameCapturerDelegate

extension LegacyWindowVideoCapturer: FrameCapturerDelegate {
    fileprivate func frameCapturer(
        _ frameCapturer: FrameCapturer,
        didCaptureVideoFrame frame: VideoFrame
    ) {
        delegate?.legacyWindowVideoCapturer(self, didCaptureVideoFrame: frame)
    }
}

// MARK: - Private types

private protocol FrameCapturerDelegate: AnyObject {
    func frameCapturer(
        _ frameCapturer: FrameCapturer,
        didCaptureVideoFrame frame: VideoFrame
    )
}

private actor FrameCapturer {
    private var numberOfRunningTasks = 0
    private var numberOfPendingTasks = 0
    private let window: Window
    private let queueDepth: Int
    private let delegate: FrameCapturerDelegate
    private var tasks = [UUID: Task<Void, Never>]()
    private let ciContext = CIContext()
    private var startTimeNs: UInt64?

    init(window: Window, queueDepth: Int, delegate: FrameCapturerDelegate) {
        self.window = window
        self.queueDepth = queueDepth
        self.delegate = delegate
    }

    deinit {
        cancelAll()
    }

    func captureFrame() {
        if numberOfRunningTasks == queueDepth {
            numberOfPendingTasks += 1
            return
        }

        let id = UUID()
        let task = Task {
            numberOfRunningTasks += 1
            async let frame = createTask(window: window).value

            if let frame = await frame {
                delegate.frameCapturer(self, didCaptureVideoFrame: frame)
            }

            numberOfRunningTasks -= 1
            tasks.removeValue(forKey: id)

            if numberOfPendingTasks > 0 {
                numberOfPendingTasks -= 1
                captureFrame()
            }
        }

        tasks[id] = task
    }

    func cancelAll() {
        for task in tasks.values {
            task.cancel()
        }
        tasks.removeAll()
    }

    private func createTask(window: Window) -> Task<VideoFrame?, Never> {
        Task {
            guard let cgImage = window.createImage() else {
                return nil
            }

            var pixelBuffer: CVPixelBuffer?

            CVPixelBufferCreate(
                kCFAllocatorDefault,
                cgImage.width,
                cgImage.height,
                kCVPixelFormatType_32BGRA,
                nil,
                &pixelBuffer
            )

            guard let pixelBuffer = pixelBuffer else {
                return nil
            }

            CVPixelBufferLockBaseAddress(pixelBuffer, .init(rawValue: 0))

            let ciImage = CIImage(cgImage: cgImage)
            ciContext.render(ciImage, to: pixelBuffer)

            CVPixelBufferUnlockBaseAddress(pixelBuffer, .init(rawValue: 0))

            let displayTimeNs = clock_gettime_nsec_np(CLOCK_UPTIME_RAW)
            startTimeNs = startTimeNs ?? displayTimeNs

            return VideoFrame(
                pixelBuffer: pixelBuffer,
                displayTimeNs: displayTimeNs,
                elapsedTimeNs: displayTimeNs - startTimeNs!
            )
        }
    }
}

#endif
