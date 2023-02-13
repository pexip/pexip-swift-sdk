//
// Copyright 2022 Pexip AS
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

import CoreVideo
import CoreImage
import PexipCore

struct CustomVideoFilter: VideoFilter {
    let ciFilter: CIFilter
    let ciContext: CIContext

    func processPixelBuffer(
        _ pixelBuffer: CVPixelBuffer,
        orientation: CGImagePropertyOrientation
    ) -> CVPixelBuffer {
        let image = CIImage(cvPixelBuffer: pixelBuffer)
        ciFilter.setValue(image, forKey: kCIInputImageKey)

        guard
            let newImage = ciFilter.outputImage,
            let newPixelBuffer = newImage.pixelBuffer(
                withTemplate: pixelBuffer,
                ciContext: ciContext
            )
        else {
            return pixelBuffer
        }

        return newPixelBuffer
    }
}
