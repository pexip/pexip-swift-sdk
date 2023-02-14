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

import CoreImage

extension CIImage {
    func resizedImage(for targetSize: CGSize) -> CIImage {
        transformed(by: CGAffineTransform(
            scaleX: targetSize.width / extent.size.width,
            y: targetSize.height / extent.size.height
        ))
    }

    func scaledToFill(_ targetSize: CGSize) -> CIImage {
        let image = resizedImage(for: extent.size.aspectFillSize(for: targetSize))
        let rect = CGRect(
            x: abs(image.extent.size.width - targetSize.width) / 2,
            y: abs(image.extent.size.height - targetSize.height) / 2,
            width: targetSize.width,
            height: targetSize.height
        )

        return image.cropped(to: rect).transformed(by: .init(
            translationX: -rect.minX,
            y: -rect.minY
        ))
    }

    func pixelBuffer(
        withTemplate template: CVPixelBuffer,
        ciContext: CIContext
    ) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?

        CVPixelBufferCreate(
            kCFAllocatorDefault,
            CVPixelBufferGetWidth(template),
            CVPixelBufferGetHeight(template),
            CVPixelBufferGetPixelFormatType(template),
            nil,
            &pixelBuffer
        )

        guard let pixelBuffer else {
            return nil
        }

        CVPixelBufferLockBaseAddress(pixelBuffer, .init(rawValue: 0))
        ciContext.render(self, to: pixelBuffer)
        CVPixelBufferUnlockBaseAddress(pixelBuffer, .init(rawValue: 0))

        return pixelBuffer
    }
}
