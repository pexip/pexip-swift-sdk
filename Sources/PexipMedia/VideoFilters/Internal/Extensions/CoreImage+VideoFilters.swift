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
}
