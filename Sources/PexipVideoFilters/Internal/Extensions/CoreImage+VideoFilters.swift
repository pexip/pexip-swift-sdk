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
