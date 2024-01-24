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

import Foundation

final class NamedPipeFile {
    static let bufferSize = 8192

    let path: String
    let fileDescriptor: Int32

    // MARK: - Init

    init(path: String, fileDescriptor: Int32) {
        self.path = path
        self.fileDescriptor = fileDescriptor
    }

    deinit {
        close(fileDescriptor)
    }

    // MARK: - Internal

    @discardableResult
    func write(_ data: Data) -> Int {
        var offset = 0
        while offset < data.count {
            let count = data.count - offset
            let bytes = write(data, offset: offset, count: count)
            if bytes > 0 {
                offset += bytes
            }
        }
        return offset
    }

    func write(_ data: Data, offset: Int, count: Int) -> Int {
        data.withUnsafeBytes { pointer -> Int in
            if let baseAddress = pointer.baseAddress {
                return Darwin.write(
                    fileDescriptor,
                    baseAddress.advanced(by: offset),
                    min(count, Self.bufferSize)
                )
            } else {
                return -1
            }
        }
    }

    @discardableResult
    func read(into data: inout Data) -> Int {
        var offset = 0
        while offset < data.count {
            let count = data.count - offset
            let bytes = read(into: &data, offset: offset, count: count)
            if bytes > 0 {
                offset += bytes
            }
        }
        return offset
    }

    func read(into data: inout Data, offset: Int, count: Int) -> Int {
        data.withUnsafeMutableBytes { pointer -> Int in
            if let baseAddress = pointer.baseAddress {
                return Darwin.read(
                    fileDescriptor,
                    baseAddress.advanced(by: offset),
                    min(count, Self.bufferSize)
                )
            } else {
                return -1
            }
        }
    }
}

#endif
