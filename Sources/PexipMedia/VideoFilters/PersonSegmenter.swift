import CoreVideo
import CoreImage.CIFilterBuiltins

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

// MARK: - Public extensions

public extension PersonSegmenter {
    /**
     Detects and generates an image mask for a person and blends it with
     the original pixel buffer and the given background image.

     - Parameters:
        - pixelBuffer: The CVPixelBuffer containing the image to be processed
        - ciContext: The context for rendering image processing results
        - backgroundImage: A closure to generate background image for the given original image
     - Returns: The CVPixelBuffer containing the resulting image
     */
    func blendWithMask(
        pixelBuffer: CVPixelBuffer,
        ciContext: CIContext,
        backgroundImage: (CIImage) -> CIImage?
    ) -> CVPixelBuffer? {
        guard let maskPixelBuffer = personMaskPixelBuffer(from: pixelBuffer) else {
            return pixelBuffer
        }

        // 1. Create CIImage objects.
        let originalImage = CIImage(cvPixelBuffer: pixelBuffer).oriented(.right)
        var maskImage = CIImage(cvPixelBuffer: maskPixelBuffer)

        // 2. Scale the mask image.
        maskImage = maskImage.resizedImage(for: originalImage.extent.size)

        // 3. Blend the original, background, and mask images.
        let blendFilter = CIFilter.blendWithMask()
        blendFilter.inputImage = originalImage
        blendFilter.backgroundImage = backgroundImage(originalImage)
        blendFilter.maskImage = maskImage

        guard
            let newImage = blendFilter.outputImage?.oriented(.left),
            let newPixelBuffer = createPixelBuffer(
                from: newImage,
                width: Int(pixelBuffer.width),
                height: Int(pixelBuffer.height),
                format: pixelBuffer.pixelFormat,
                ciContext: ciContext
            )
        else {
            return pixelBuffer
        }

        return newPixelBuffer
    }

    /**
     Creates CVPixelBuffer from the given CIImage.

     - Parameters:
        - image: The input image
        - width: The width of the pixel buffer
        - height: The height of the pixel buffer
        - format: The pixel format of the pixel buffer
        - ciContext: The context for rendering image processing results
     - Returns: The pixel buffer created from the given input image
     */
    func createPixelBuffer(
        from image: CIImage,
        width: Int,
        height: Int,
        format: OSType,
        ciContext: CIContext
    ) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?

        CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            format,
            nil,
            &pixelBuffer
        )

        guard let pixelBuffer = pixelBuffer else {
            return nil
        }

        pixelBuffer.lockBaseAddress(.init(rawValue: 0))
        ciContext.render(image, to: pixelBuffer)
        pixelBuffer.unlockBaseAddress(.init(rawValue: 0))

        return pixelBuffer
    }
}
