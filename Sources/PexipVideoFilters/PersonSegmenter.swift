import CoreVideo

/// An object that detects and generates an image mask for a person in an image.
public protocol PersonSegmenter {
    /**
     Detects and generates an image mask for a person in the given pixel buffer.

     - Parameters:
        - pixelBuffer: The CVPixelBuffer containing the image to be processed.
     - Returns: The CVPixelBuffer containing the resulting image mask.
     */
    func personMaskPixelBuffer(from pixelBuffer: CVPixelBuffer) -> CVPixelBuffer?
}
