import CoreImage

protocol ImageFilter {
    func processImage(
        _ image: CIImage,
        withSize size: CGSize,
        orientation: CGImagePropertyOrientation
    ) -> CIImage?
}
