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
import CoreImage.CIFilterBuiltins
import PexipCore

final class SegmentationVideoFilter: VideoFilter {
    private let segmenter: PersonSegmenter
    private let backgroundFilter: ImageFilter
    private let globalFilters: [CIFilter]
    private let ciContext: CIContext

    // MARK: - Init

    init(
        segmenter: PersonSegmenter,
        backgroundFilter: ImageFilter,
        globalFilters: [CIFilter],
        ciContext: CIContext
    ) {
        self.segmenter = segmenter
        self.backgroundFilter = backgroundFilter
        self.globalFilters = globalFilters
        self.ciContext = ciContext
    }

    deinit {
        ciContext.clearCaches()
    }

    // MARK: - VideoFilter

    func processPixelBuffer(
        _ pixelBuffer: CVPixelBuffer,
        orientation: CGImagePropertyOrientation
    ) -> CVPixelBuffer {
        guard let maskPixelBuffer = segmenter.personMaskPixelBuffer(
            from: pixelBuffer
        ) else {
            return pixelBuffer
        }

        // 1. Create CIImage objects.
        var originalImage = CIImage(cvPixelBuffer: pixelBuffer)
        var maskImage = CIImage(cvPixelBuffer: maskPixelBuffer)

        // 2. Scale the mask image.
        maskImage = maskImage.resizedImage(for: originalImage.extent.size)

        // 3. Apply global image filters (if any)
        originalImage = globalFilters.reduce(originalImage, { image, filter in
            filter.setValue(image, forKey: kCIInputImageKey)
            return filter.outputImage ?? image
        })

        // 4. Apply background effect
        let originalWidth = CVPixelBufferGetWidth(pixelBuffer)
        let originalHeight = CVPixelBufferGetHeight(pixelBuffer)
        let isVertical = orientation.isVertical
        let backgroundImage = backgroundFilter.processImage(
            originalImage,
            withSize: CGSize(
                width: Int(isVertical ? originalWidth : originalHeight),
                height: Int(isVertical ? originalHeight : originalWidth)
            ),
            orientation: orientation
        )

        // 5. Blend the original, background, and mask images.
        let blendFilter = CIFilter.blendWithMask()
        blendFilter.setValue(originalImage, forKey: kCIInputImageKey)
        blendFilter.setValue(maskImage, forKey: kCIInputMaskImageKey)
        blendFilter.setValue(backgroundImage, forKey: kCIInputBackgroundImageKey)

        return blendFilter.outputImage?.pixelBuffer(
            withTemplate: pixelBuffer,
            ciContext: ciContext
        ) ?? pixelBuffer
    }
}
