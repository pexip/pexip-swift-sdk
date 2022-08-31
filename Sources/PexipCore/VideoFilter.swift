import CoreVideo
import CoreImage

/// A video processor that produces a new image
/// by manipulating the input video frame data.
public protocol VideoFilter {
    /**
     Produces a new image by manipulating the input video frame data.

     - Parameters:
        - pixelBuffer: The CVPixelBuffer containing the image to be processed.
        - orientation: A value describing the intended display orientation for an image.

     - Returns: The CVPixelBuffer containing the resulting image.
     */
    func processPixelBuffer(
        _ pixelBuffer: CVPixelBuffer,
        orientation: CGImagePropertyOrientation
    ) -> CVPixelBuffer
}
