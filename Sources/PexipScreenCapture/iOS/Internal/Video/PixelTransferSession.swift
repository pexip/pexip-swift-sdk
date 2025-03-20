//
// Copyright 2025 Pexip AS
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
import VideoToolbox

// MARK: - Protocol

protocol PixelTransferSession {
    func transfer(_ inputBuffer: CVPixelBuffer) -> CVPixelBuffer
}

// MARK: - Implementation

@available(iOS 16.0, *)
final class VideoToolboxTransferSession: PixelTransferSession {
    private var session: VTPixelTransferSession?
    private var bufferPool: CVPixelBufferPool?
    private var width: UInt32 = 0
    private var height: UInt32 = 0

    // MARK: - Init

    init() {
        VTPixelTransferSessionCreate(
            allocator: nil,
            pixelTransferSessionOut: &session
        )
    }

    deinit {
        if let session {
            VTPixelTransferSessionInvalidate(session)
            self.session = nil
        }
    }

    // MARK: - Transfer

    func transfer(_ inputBuffer: CVPixelBuffer) -> CVPixelBuffer {
        inputBuffer.lockBaseAddress(.readOnly)

        defer {
            inputBuffer.unlockBaseAddress(.readOnly)
        }

        if bufferPool == nil || inputBuffer.width != width || inputBuffer.height != height {
            bufferPool = CVPixelBufferPool.createWithTemplate(inputBuffer)
            width = inputBuffer.width
            height = inputBuffer.height
        }

        guard let bufferPool else {
            return inputBuffer
        }

        var outputBuffer: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(nil, bufferPool, &outputBuffer)

        guard let session, let outputBuffer else {
            return inputBuffer
        }

        VTPixelTransferSessionTransferImage(session, from: inputBuffer, to: outputBuffer)

        return outputBuffer
    }
}

#endif
