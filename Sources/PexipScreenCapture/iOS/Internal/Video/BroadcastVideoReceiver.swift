//
// Copyright 2023-2025 Pexip AS
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

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
    private var bufferPool: CVPixelBufferPool?
    private var bufferPoolWidth: UInt32 = 0
    private var bufferPoolHeight: UInt32 = 0
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
            var format: UInt32 = 0
            var width: UInt32 = 0
            var height: UInt32 = 0
            var videoOrientation: UInt32 = 0

            func copyMemory<T>(to value: inout T) {
                let count = MemoryLayout<T>.size
                withUnsafeMutablePointer(to: &value) { valuePointer in
                    valuePointer.withMemoryRebound(to: UInt8.self, capacity: count) { pointer in
                        let source = baseAddress.advanced(by: position)
                        let destination = UnsafeMutableRawPointer(pointer)
                        destination.copyMemory(from: source, byteCount: count)
                    }
                }
                position += count
            }

            copyMemory(to: &displayTimeNs)
            copyMemory(to: &format)
            copyMemory(to: &width)
            copyMemory(to: &height)
            copyMemory(to: &videoOrientation)

            guard let pixelBuffer = pixelBuffer(width: width, height: height, format: format) else {
                return nil
            }

            pixelBuffer.lockBaseAddress([])

            defer {
                pixelBuffer.unlockBaseAddress([])
            }

            for index in 0..<pixelBuffer.planeCount {
                let plane = pixelBuffer.plane(at: index)
                if let planeBaseAddress = plane.baseAddress {
                    let source = baseAddress.advanced(by: position)
                    let destination = UnsafeMutableRawPointer(planeBaseAddress)
                    destination.copyMemory(from: source, byteCount: plane.size)
                    position += plane.size
                }
            }

            return VideoFrame(
                pixelBuffer: pixelBuffer,
                orientation: .init(rawValue: videoOrientation) ?? .up,
                displayTimeNs: displayTimeNs
            )
        }
    }

    private func pixelBuffer(
        width: UInt32,
        height: UInt32,
        format: OSType
    ) -> CVPixelBuffer? {
        if bufferPool == nil || width != bufferPoolWidth || height != bufferPoolHeight {
            bufferPool = CVPixelBufferPool.createWithAttributes(
                width: width,
                height: height,
                pixelFormat: format
            )
            bufferPoolWidth = width
            bufferPoolHeight = height
        }

        return bufferPool?.createPixelBuffer()
    }
}

#endif
