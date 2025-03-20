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

import CoreMedia

final class BroadcastVideoSender {
    var isRunning: Bool { _isRunning.value }

    private let filePath: String
    private let fileManager: FileManager
    private var file: MemoryMappedFile?
    private var transferSession: PixelTransferSession?
    private var displayLink: BroadcastDisplayLink?
    private let queue = DispatchQueue(
        label: "com.pexip.PexipScreenCapture.BroadcastVideoSender",
        qos: .userInteractive,
        autoreleaseFrequency: .workItem
    )
    private let canWrite = Synchronized(false)
    private let _isRunning = Synchronized(false)

    // MARK: - Init

    init(
        filePath: String,
        fileManager: FileManager = .default
    ) {
        self.filePath = filePath
        self.fileManager = fileManager
        if #available(iOS 16.0, *) {
            self.transferSession = VideoToolboxTransferSession()
        }
    }

    deinit {
        stop()
    }

    // MARK: - Internal

    @discardableResult
    func start(withFps fps: BroadcastFps) throws -> Bool {
        guard !_isRunning.value else {
            return false
        }

        file = fileManager.mappedFile(atPath: filePath)

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
    func stop() -> Bool {
        guard _isRunning.value else {
            return false
        }

        _isRunning.setValue(false)
        file = nil
        displayLink?.invalidate()
        displayLink = nil

        return true
    }

    @discardableResult
    func send(_ sampleBuffer: CMSampleBuffer) -> Bool {
        guard _isRunning.value, canWrite.value else {
            return false
        }

        canWrite.setValue(false)
        queue.async { [weak self] in
            self?.write(sampleBuffer)
        }

        return true
    }

    // MARK: - Private

    private func onDisplayLink() {
        canWrite.setValue(true)
    }

    private func write(_ sampleBuffer: CMSampleBuffer) {
        guard let timestamp = displayLink?.timestamp else {
            return
        }

        guard let pixelBuffer = sampleBuffer.imageBuffer else {
            return
        }

        let displayTimeNs = UInt64(
            llround(timestamp * Float64(NSEC_PER_SEC))
        )

        guard let data = encode(
            pixelBuffer: transferSession?.transfer(pixelBuffer) ?? pixelBuffer,
            videoOrientation: sampleBuffer.videoOrientation,
            displayTimeNs: displayTimeNs
        ) else {
            return
        }

        file?.write(data)
    }

    private func encode(
        pixelBuffer: CVPixelBuffer,
        videoOrientation: UInt32,
        displayTimeNs: UInt64
    ) -> Data? {
        pixelBuffer.lockBaseAddress(.readOnly)

        defer {
            pixelBuffer.unlockBaseAddress(.readOnly)
        }

        var data = Data()

        func appendToData<T>(_ value: T) {
            var value = value
            withUnsafeBytes(of: &value) { buffer in
                if let baseAddress = buffer.baseAddress {
                    data.append(start: baseAddress, count: buffer.count)
                }
            }
        }

        appendToData(displayTimeNs)
        appendToData(pixelBuffer.pixelFormat)
        appendToData(pixelBuffer.width)
        appendToData(pixelBuffer.height)
        appendToData(videoOrientation)

        for index in 0..<pixelBuffer.planeCount {
            let plane = pixelBuffer.plane(at: index)
            if let baseAddress = plane.baseAddress {
                data.append(start: baseAddress, count: plane.size)
            }
        }

        return data
    }
}

#endif
