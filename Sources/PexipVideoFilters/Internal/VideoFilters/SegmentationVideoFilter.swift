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
        blendFilter.inputImage = originalImage
        blendFilter.backgroundImage = backgroundImage
        blendFilter.maskImage = maskImage

        return blendFilter.outputImage?.pixelBuffer(
            withTemplate: pixelBuffer,
            ciContext: ciContext
        ) ?? pixelBuffer
    }
}
