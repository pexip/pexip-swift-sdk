//
// Copyright 2022-2024 Pexip AS
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

import Foundation

extension FileManager {
    func broadcastVideoDataPath(appGroup: String) -> String {
        broadcastDataPath(appGroup: appGroup, name: "pex_broadcast_video")
    }

    func broadcastAudioDataPath(appGroup: String) -> String {
        broadcastDataPath(appGroup: appGroup, name: "pex_broadcast_audio")
    }

    func namedPipeFile(
        atPath path: String,
        createIfNeeded: Bool = false
    ) throws -> NamedPipeFile? {
        let fileDescriptor: Int32
        if createIfNeeded {
            if fileExists(atPath: path) {
                try removeItem(atPath: path)
            }

            unlink(path)
            mkfifo(path, 0o666)
            fileDescriptor = open(path, O_RDONLY | O_NONBLOCK, Self.mode)
        } else {
            fileDescriptor = open(path, O_WRONLY | O_NONBLOCK, Self.mode)
        }

        guard fileDescriptor != -1 else {
            return nil
        }

        return NamedPipeFile(path: path, fileDescriptor: fileDescriptor)
    }

    func createMappedFile(atPath path: String, size: Int) throws -> MemoryMappedFile? {
        if fileExists(atPath: path) {
            try removeItem(atPath: path)
        }

        let fileDescriptor = open(path, O_RDWR | O_APPEND | O_CREAT, Self.mode)

        if fileDescriptor < 0 {
            return nil
        }

        ftruncate(fileDescriptor, off_t(size))

        return MemoryMappedFile(
            path: path,
            fileDescriptor: fileDescriptor,
            size: size
        )
    }

    func mappedFile(atPath path: String) -> MemoryMappedFile? {
        let fileDescriptor = open(path, O_RDWR | O_APPEND, Self.mode)

        if fileDescriptor < 0 {
            return nil
        }

        var fileInfo = stat()
        stat(path, &fileInfo)

        return MemoryMappedFile(
            path: path,
            fileDescriptor: fileDescriptor,
            size: Int(fileInfo.st_size)
        )
    }

    // MARK: - Private

    private func broadcastDataPath(appGroup: String, name: String) -> String {
        let url = containerURL(
            forSecurityApplicationGroupIdentifier: appGroup
        )
        return url?.appendingPathComponent(name).path ?? name
    }

    private static let mode: mode_t = S_IRUSR | S_IWUSR
}

#endif
