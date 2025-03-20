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

import Foundation

final class MemoryMappedFile {
    let path: String
    let size: Int
    private let fileDescriptor: Int32
    private var memory: UnsafeMutableRawPointer

    // MARK: - Init

    init(path: String, fileDescriptor: Int32, size: Int) {
        self.path = path
        self.fileDescriptor = fileDescriptor
        self.size = size
        memory = mmap(
            nil,
            size,
            PROT_READ | PROT_WRITE,
            MAP_SHARED,
            fileDescriptor,
            0
        )
    }

    deinit {
        munmap(memory, size)
        close(fileDescriptor)
    }

    // MARK: - Internal

    @discardableResult
    func write(_ data: Data) -> Bool {
        guard data.count <= size else {
            return false
        }

        data.withUnsafeBytes { pointer in
            if let baseAddress = pointer.baseAddress {
                memory.copyMemory(from: baseAddress, byteCount: data.count)
            }
        }

        return true
    }

    func read() -> Data {
        Data(bytesNoCopy: memory, count: size, deallocator: .none)
    }
}

#endif
