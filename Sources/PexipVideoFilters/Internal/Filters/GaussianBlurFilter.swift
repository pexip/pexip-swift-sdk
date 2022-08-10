import CoreImage

final class GaussianBlurFilter: VideoFilter {
    private let ciContext: CIContext
    private let segmenter: PersonSegmenter
    private let radius: Float

    // MARK: - Init

    init(
        radius: Float,
        segmenter: PersonSegmenter,
        ciContext: CIContext
    ) {
        self.radius = radius
        self.segmenter = segmenter
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
        let newPixelBuffer = segmenter.blendWithMask(
            pixelBuffer: pixelBuffer,
            ciContext: ciContext,
            backgroundImage: { [weak self] originalImage in
                self?.blurredImage(from: originalImage)
            }
        )
        return newPixelBuffer ?? pixelBuffer
    }

    // MARK: - Private

    private func blurredImage(from originalImage: CIImage) -> CIImage? {
        let blendFilter = CIFilter.gaussianBlur()
        blendFilter.inputImage = originalImage
        blendFilter.radius = radius
        return blendFilter.outputImage?.cropped(to: originalImage.extent)
    }
}
