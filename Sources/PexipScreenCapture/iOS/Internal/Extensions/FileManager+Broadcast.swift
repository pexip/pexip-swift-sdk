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

import Foundation

extension FileManager {
    func broadcastVideoDataPath(appGroup: String) -> String {
        let url = containerURL(
            forSecurityApplicationGroupIdentifier: appGroup
        )
        let suffix = "pex_broadcast_video"
        return url?.appendingPathComponent(suffix).path ?? suffix
    }

    func createMappedFile(atPath path: String, size: Int) throws -> MemoryMappedFile? {
        if fileExists(atPath: path) {
            try removeItem(atPath: path)
        }

        let fileDescriptor = openFile(atPath: path, createIfNeeded: true)

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
        let fileDescriptor = openFile(atPath: path, createIfNeeded: false)

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

    private func openFile(
        atPath path: String,
        createIfNeeded: Bool
    ) -> Int32 {
        var oflag: Int32 = O_RDWR | O_APPEND

        if createIfNeeded {
            oflag |= O_CREAT
        }

        return open(path, oflag, S_IRUSR | S_IWUSR)
    }
}

#endif
