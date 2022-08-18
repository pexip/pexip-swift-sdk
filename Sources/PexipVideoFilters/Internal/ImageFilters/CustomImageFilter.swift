import CoreImage

struct CustomImageFilter: ImageFilter {
    let ciFilter: CIFilter

    func processImage(
        _ image: CIImage,
        withSize size: CGSize,
        orientation: CGImagePropertyOrientation
    ) -> CIImage? {
        ciFilter.setValue(image, forKey: kCIInputImageKey)
        return ciFilter.outputImage?.cropped(to: image.extent)
    }
}
