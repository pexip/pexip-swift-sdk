#if os(macOS)

import AppKit
import CoreMedia
import Combine

/**
 Quartz Window Services -based window video capturer.
 https://developer.apple.com/documentation/coregraphics/quartz_window_services
 */
final class LegacyWindowVideoCapturer: ScreenVideoCapturer {
    let window: Window
    weak var delegate: ScreenVideoCapturerDelegate?
    private(set) var isCapturing = false
    var displayTimeNs: () -> UInt64 = {
        clock_gettime_nsec_np(CLOCK_UPTIME_RAW)
    }

    private var timer: Timer?
    private var frameCapturer: FrameCapturer?

    // MARK: - Init

    init(window: Window) {
        self.window = window
    }

    deinit {
        try? stopCapture()
    }

    // MARK: - Capture

    func startCapture(withFps fps: UInt) async throws {
        try stopCapture()

        frameCapturer = FrameCapturer(
            window: window,
            queueDepth: 3,
            delegate: self,
            displayTimeNs: { [weak self] in
                self?.displayTimeNs() ?? 0
            }
        )

        DispatchQueue.main.async { [weak self] in
            self?.timer = Timer.scheduledTimer(
                withTimeInterval: CMTime(fps: fps).seconds,
                repeats: true,
                block: { _ in
                    Task { [weak self] in
                        await self?.frameCapturer?.captureFrame()
                    }
                })
        }

        isCapturing = true
    }

    func stopCapture() throws {
        timer?.invalidate()
        timer = nil
        frameCapturer = nil
        isCapturing = false
    }
}

// MARK: - FrameCapturerDelegate

extension LegacyWindowVideoCapturer: FrameCapturerDelegate {
    fileprivate func frameCapturer(
        _ frameCapturer: FrameCapturer,
        didCaptureVideoFrame frame: VideoFrame
    ) {
        delegate?.screenVideoCapturer(self, didCaptureVideoFrame: frame)
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
    private let displayTimeNs: () -> UInt64

    init(
        window: Window,
        queueDepth: Int,
        delegate: FrameCapturerDelegate,
        displayTimeNs: @escaping () -> UInt64
    ) {
        self.window = window
        self.queueDepth = queueDepth
        self.delegate = delegate
        self.displayTimeNs = displayTimeNs
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

            pixelBuffer.lockBaseAddress(.init(rawValue: 0))

            let ciImage = CIImage(cgImage: cgImage)
            ciContext.render(ciImage, to: pixelBuffer)

            pixelBuffer.unlockBaseAddress(.init(rawValue: 0))

            let displayTimeNs = self.displayTimeNs()
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
