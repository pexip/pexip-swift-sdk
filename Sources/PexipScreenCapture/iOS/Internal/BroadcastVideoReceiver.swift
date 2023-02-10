#if os(iOS)

import CoreVideo

// MARK: - BroadcastVideoReceiverDelegate

protocol BroadcastVideoReceiverDelegate: AnyObject {
    func broadcastVideoReceiver(
        _ receiver: BroadcastVideoReceiver,
        didReceiveVideoFrame frame: VideoFrame
    )
}

// MARK: - BroadcastVideoReceiver

final class BroadcastVideoReceiver {
    static let maxFileSize = 10 * 1024 * 1024

    weak var delegate: BroadcastVideoReceiverDelegate?
    var isRunning: Bool { _isRunning.value }

    private let filePath: String
    private let fileManager: FileManager
    private var file: MemoryMappedFile?
    private let queue = DispatchQueue(
        label: "com.pexip.PexipScreenCapture.BroadcastVideoReceiver",
        qos: .userInteractive,
        autoreleaseFrequency: .workItem
    )
    private var displayLink: BroadcastDisplayLink?
    private let _isRunning = Synchronized(false)

    // MARK: - Init

    init(
        filePath: String,
        fileManager: FileManager = .default
    ) {
        self.filePath = filePath
        self.fileManager = fileManager
    }

    deinit {
        _ = try? stop()
    }

    // MARK: - Internal

    @discardableResult
    func start(withFps fps: BroadcastFps) throws -> Bool {
        guard !_isRunning.value else {
            return false
        }

        file = try fileManager.createMappedFile(
            atPath: filePath,
            size: Self.maxFileSize
        )

        guard file != nil else {
            throw BroadcastError.noConnection
        }

        _isRunning.setValue(true)

        displayLink = BroadcastDisplayLink(fps: fps, handler: { [weak self] in
            self?.onDisplayLink()
        })

        return true
    }

    @discardableResult
    func stop() throws -> Bool {
        guard _isRunning.value else {
            return false
        }

        _isRunning.setValue(false)
        displayLink?.invalidate()
        displayLink = nil

        let filePath = file?.path
        file = nil

        if let filePath {
            try fileManager.removeItem(atPath: filePath)
        }

        return true
    }

    // MARK: - Private

    private func onDisplayLink() {
        queue.async { [weak self] in
            self?.readCurrentFrame()
        }
    }

    private func readCurrentFrame() {
        guard let file = file else {
            return
        }

        let data = file.read()

        guard let videoFrame = decode(from: data) else {
            return
        }

        delegate?.broadcastVideoReceiver(self, didReceiveVideoFrame: videoFrame)
    }

    private func decode(from data: Data) -> VideoFrame? {
        data.withUnsafeBytes { buffer -> VideoFrame? in
            guard let baseAddress = buffer.baseAddress, !buffer.isEmpty else {
                return nil
            }

            var position = 0
            var displayTimeNs: UInt64 = 0
            var pixelFormat: UInt32 = 0
            var width: UInt32 = 0
            var height: UInt32 = 0
            var videoOrientation: UInt32 = 0
            var pixelBuffer: CVPixelBuffer?

            func copyMemory<T>(to value: inout T) {
                let count = MemoryLayout<T>.size
                memcpy(&value, baseAddress.advanced(by: position), count)
                position += count
            }

            copyMemory(to: &displayTimeNs)
            copyMemory(to: &pixelFormat)
            copyMemory(to: &width)
            copyMemory(to: &height)
            copyMemory(to: &videoOrientation)

            let result = CVPixelBufferCreate(
                kCFAllocatorDefault,
                Int(width),
                Int(height),
                pixelFormat,
                nil,
                &pixelBuffer
            )

            guard let pixelBuffer, result == kCVReturnSuccess else {
                return nil
            }

            pixelBuffer.lockBaseAddress([])

            defer {
                pixelBuffer.unlockBaseAddress([])
            }

            for index in 0..<pixelBuffer.planeCount {
                let plane = pixelBuffer.plane(at: index)
                memcpy(plane.baseAddress, baseAddress.advanced(by: position), plane.size)
                position += plane.size
            }

            return VideoFrame(
                pixelBuffer: pixelBuffer,
                orientation: .init(rawValue: videoOrientation) ?? .up,
                displayTimeNs: displayTimeNs
            )
        }
    }
}

#endif
