//
// Copyright 2022-2023 Pexip AS
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

        let displayTimeNs = UInt64(
            llround(timestamp * Float64(NSEC_PER_SEC))
        )

        guard let data = encode(
            sampleBuffer: sampleBuffer,
            displayTimeNs: displayTimeNs
        ) else {
            return
        }

        file?.write(data)
    }

    private func encode(
        sampleBuffer: CMSampleBuffer,
        displayTimeNs: UInt64
    ) -> Data? {
        guard let pixelBuffer = sampleBuffer.imageBuffer else {
            return nil
        }

        pixelBuffer.lockBaseAddress(.readOnly)

        defer {
            pixelBuffer.unlockBaseAddress(.readOnly)
        }

        var planes = [CVPixelBuffer.Plane]()
        var pixelBufferSize = 0

        for index in 0..<pixelBuffer.planeCount {
            let plane = pixelBuffer.plane(at: index)
            planes.append(plane)
            pixelBufferSize += plane.size
        }

        let headerSize = MemoryLayout<UInt64>.size + MemoryLayout<UInt32>.size * 5
        let totalSize = headerSize + pixelBufferSize

        guard let pointer = malloc(totalSize) else {
            return nil
        }

        var displayTimeNs = displayTimeNs
        var pixelFormat = pixelBuffer.pixelFormat
        var width = pixelBuffer.width
        var height = pixelBuffer.height
        var videoOrientation = sampleBuffer.videoOrientation
        var position = 0

        func copyMemory<T>(from value: inout T) {
            let count = MemoryLayout<T>.size
            withUnsafeMutablePointer(to: &value) { pointer in
                memcpy(pointer.advanced(by: position), pointer, count)
                position += count
            }
        }

        copyMemory(from: &displayTimeNs)
        copyMemory(from: &pixelFormat)
        copyMemory(from: &width)
        copyMemory(from: &height)
        copyMemory(from: &videoOrientation)

        for plane in planes {
            memcpy(pointer.advanced(by: position), plane.baseAddress, plane.size)
            position += plane.size
        }

        return Data(bytesNoCopy: pointer, count: totalSize, deallocator: .free)
    }
}

#endif
