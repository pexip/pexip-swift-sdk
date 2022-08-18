import CoreVideo
import CoreImage

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
