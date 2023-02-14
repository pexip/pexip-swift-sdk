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

import CoreVideo

extension CVPixelBuffer {
    struct Plane {
        let baseAddress: UnsafeMutableRawPointer?
        let bytesPerRow: Int
        let height: Int

        var size: Int {
            height * bytesPerRow
        }
    }

    var planeCount: Int {
        CVPixelBufferGetPlaneCount(self)
    }

    func plane(at index: Int) -> Plane {
        Plane(
            baseAddress: CVPixelBufferGetBaseAddressOfPlane(self, index),
            bytesPerRow: CVPixelBufferGetBytesPerRowOfPlane(self, index),
            height: CVPixelBufferGetHeightOfPlane(self, index)
        )
    }
}

#endif
