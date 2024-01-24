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
import Foundation

struct AudioBufferHeader {
    static let size = MemoryLayout<AudioBufferHeader>.size

    var streamDescription = AudioStreamBasicDescription()
    var dataSize: UInt32 = 0

    // MARK: - Encoding/Decoding

    func encoded() -> Data? {
        var offset = 0
        var header = self

        guard var data = Self.allocateData() else {
            return nil
        }

        data.withUnsafeMutableBytes { pointer in
            guard let baseAddress = pointer.baseAddress, !pointer.isEmpty else {
                return
            }
            baseAddress.copyMemory(from: &header, offset: &offset)
        }

        return data
    }

    static func decode(from data: Data) -> AudioBufferHeader? {
        data.withUnsafeBytes { pointer -> AudioBufferHeader? in
            guard let baseAddress = pointer.baseAddress, !pointer.isEmpty else {
                return nil
            }

            var offset = 0
            var header = AudioBufferHeader()
            baseAddress.copyMemory(to: &header, offset: &offset)

            guard header.dataSize > 0 else {
                return nil
            }

            return header
        }
    }

    static func allocateData() -> Data? {
        .allocateData(withSize: Self.size)
    }
}

#endif
