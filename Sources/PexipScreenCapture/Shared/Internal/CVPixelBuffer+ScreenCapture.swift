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

import Foundation
import CoreVideo

extension CVPixelBuffer {
    var pixelFormat: UInt32 {
        CVPixelBufferGetPixelFormatType(self)
    }

    var width: UInt32 {
        UInt32(CVPixelBufferGetWidth(self))
    }

    var height: UInt32 {
        UInt32(CVPixelBufferGetHeight(self))
    }

    func lockBaseAddress(_ flags: CVPixelBufferLockFlags) {
        CVPixelBufferLockBaseAddress(self, flags)
    }

    func unlockBaseAddress(_ flags: CVPixelBufferLockFlags) {
        CVPixelBufferUnlockBaseAddress(self, flags)
    }
}
