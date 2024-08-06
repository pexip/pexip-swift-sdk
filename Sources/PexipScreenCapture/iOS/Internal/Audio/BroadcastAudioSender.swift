//
// Copyright 2024 Pexip AS
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

import AVFoundation
import CoreMedia

final class BroadcastAudioSender {
    var isRunning: Bool { _isRunning.value }

    private static let maxQueueSize = 2 * 1024 * 1024
    private let filePath: String
    private let fileManager: FileManager
    private var file: NamedPipeFile?
    private let queue = DispatchQueue(
        label: "com.pexip.PexipScreenCapture.BroadcastAudioSender",
        qos: .userInteractive,
        autoreleaseFrequency: .workItem
    )
    private var source: DispatchSourceWrite?
    private var messageQueue = [AudioBufferMessage]()
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
    func start() throws -> Bool {
        guard !_isRunning.value else {
            return false
        }

        file = try fileManager.namedPipeFile(atPath: filePath)

        guard let fileDescriptor = file?.fileDescriptor else {
            throw BroadcastError.noConnection
        }

        _isRunning.setValue(true)

        source = DispatchSource.makeWriteSource(
            fileDescriptor: fileDescriptor,
            queue: queue
        )

        source?.setEventHandler { [weak self] in
            self?.handleSourceEvents()
        }
        source?.activate()

        return true
    }

    @discardableResult
    func stop() -> Bool {
        guard _isRunning.value else {
            return false
        }

        _isRunning.setValue(false)
        source?.cancel()
        source = nil
        file = nil
        messageQueue.removeAll()

        return true
    }

    @discardableResult
    func send(_ sampleBuffer: CMSampleBuffer) -> Bool {
        guard _isRunning.value else {
            return false
        }

        queue.async { [weak self] in
            try? self?.write(sampleBuffer)
        }

        return true
    }

    // MARK: - Private

    private func write(_ buffer: CMSampleBuffer) throws {
        guard messageQueue.reduce(0, { $0 + $1.size }) < Self.maxQueueSize else {
            return
        }

        let messages: [AudioBufferMessage] = try buffer.withAudioBufferList { list, _ in
            guard
                let streamDescription = buffer.formatDescription?.audioStreamBasicDescription,
                let firstBuffer = list.first,
                let firstBufferPointer = firstBuffer.mData
            else {
                return []
            }

            let header = AudioBufferHeader(
                streamDescription: streamDescription,
                dataSize: firstBuffer.mDataByteSize * UInt32(list.count)
            )

            guard let pointer = malloc(Int(header.dataSize)) else {
                return []
            }

            memcpy(pointer, firstBufferPointer, Int(header.dataSize))

            let data = Data(
                bytesNoCopy: pointer,
                count: Int(header.dataSize),
                deallocator: .free
            )

            return [.header(header), .data(data)]
        }

        messageQueue.append(contentsOf: messages)
    }

    private func handleSourceEvents() {
        guard let file else {
            return
        }

        guard !messageQueue.isEmpty else {
            return
        }

        guard let data = messageQueue.removeFirst().encoded() else {
            return
        }

        file.write(data)
    }
}

#endif
