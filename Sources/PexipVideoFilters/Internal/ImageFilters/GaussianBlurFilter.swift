import CoreImage

struct GaussianBlurFilter: ImageFilter {
    let radius: Float

    func processImage(
        _ image: CIImage,
        withSize size: CGSize,
        orientation: CGImagePropertyOrientation
    ) -> CIImage? {
        let ciFilter = CIFilter.gaussianBlur()
        ciFilter.radius = radius

        let filter = CustomImageFilter(ciFilter: ciFilter)
        return filter.processImage(image, withSize: size, orientation: orientation)
    }
}
