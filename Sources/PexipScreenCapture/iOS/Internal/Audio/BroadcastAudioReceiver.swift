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
import CoreVideo

// MARK: - BroadcastAudioReceiverDelegate

protocol BroadcastAudioReceiverDelegate: AnyObject {
    func broadcastAudioReceiver(
        _ receiver: BroadcastAudioReceiver,
        didReceiveAudioFrame frame: AudioFrame
    )
}

// MARK: - BroadcastAudioReceiver

final class BroadcastAudioReceiver {
    weak var delegate: BroadcastAudioReceiverDelegate?
    var isRunning: Bool { _isRunning.value }

    private let filePath: String
    private let fileManager: FileManager
    private var file: NamedPipeFile?
    private let queue = DispatchQueue(
        label: "com.pexip.PexipScreenCapture.BroadcastAudioReceiver",
        qos: .userInteractive,
        autoreleaseFrequency: .workItem
    )
    private var source: DispatchSourceRead?
    private var header: AudioBufferHeader?
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
    func start() throws -> Bool {
        guard !_isRunning.value else {
            return false
        }

        file = try fileManager.namedPipeFile(
            atPath: filePath,
            createIfNeeded: true
        )

        guard let fileDescriptor = file?.fileDescriptor else {
            throw BroadcastError.noConnection
        }

        _isRunning.setValue(true)

        source = DispatchSource.makeReadSource(
            fileDescriptor: fileDescriptor,
            queue: queue
        )
        source?.setEventHandler { [weak self] in
            self?.handleSourceEvents()
        }
        source?.resume()

        return true
    }

    @discardableResult
    func stop() throws -> Bool {
        guard _isRunning.value else {
            return false
        }

        _isRunning.setValue(false)
        source?.cancel()
        source = nil

        let filePath = file?.path
        file = nil
        header = nil

        if let filePath {
            try fileManager.removeItem(atPath: filePath)
        }

        return true
    }

    // MARK: - Private

    private func handleSourceEvents() {
        if let header {
            readAudioData(withHeader: header)
            self.header = nil
        } else {
            readHeader()
        }
    }

    private func readHeader() {
        guard let file, var data = AudioBufferHeader.allocateData() else {
            return
        }

        guard file.read(into: &data) == AudioBufferHeader.size else {
            return
        }

        header = AudioBufferHeader.decode(from: data)
    }

    private func readAudioData(withHeader header: AudioBufferHeader) {
        guard
            let file,
            var audioData = Data.allocateData(withSize: Int(header.dataSize))
        else {
            return
        }

        guard file.read(into: &audioData) == header.dataSize else {
            return
        }

        let frame = AudioFrame(
            streamDescription: header.streamDescription,
            data: audioData
        )

        delegate?.broadcastAudioReceiver(self, didReceiveAudioFrame: frame)
    }
}

#endif
