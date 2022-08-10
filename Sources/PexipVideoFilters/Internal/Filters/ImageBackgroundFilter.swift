import Foundation
import CoreImage

final class ImageBackgroundFilter: VideoFilter {
    private let ciContext: CIContext
    private let segmenter: PersonSegmenter
    private let backgroundImage: CGImage
    private var imageCache = NSCache<CacheKey, CIImage>()

    // MARK: - Init

    init(
        backgroundImage: CGImage,
        segmenter: PersonSegmenter,
        ciContext: CIContext
    ) {
        self.backgroundImage = backgroundImage
        self.segmenter = segmenter
        self.ciContext = ciContext
    }

    deinit {
        ciContext.clearCaches()
        imageCache.removeAllObjects()
    }

    // MARK: - VideoFilter

    func processPixelBuffer(
        _ pixelBuffer: CVPixelBuffer,
        orientation: CGImagePropertyOrientation
    ) -> CVPixelBuffer {
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let newPixelBuffer = segmenter.blendWithMask(
            pixelBuffer: pixelBuffer,
            ciContext: ciContext,
            backgroundImage: { [weak self] _ in
                let isVertical = orientation.isVertical
                return self?.image(
                    forSize: CGSize(
                        width: Int(isVertical ? height : width),
                        height: Int(isVertical ? width : height)
                    ),
                    orientation: orientation
                )
            }
        )
        return newPixelBuffer ?? pixelBuffer
    }

    private func image(
        forSize size: CGSize,
        orientation: CGImagePropertyOrientation
    ) -> CIImage? {
        let cacheKey = CacheKey(size: size, orientation: orientation)

        if let image = imageCache.object(forKey: cacheKey) {
            return image
        } else {
            if let cgImage = backgroundImage.scaledToFill(size) {
                let ciImage = CIImage(cgImage: cgImage).oriented(orientation)
                imageCache.setObject(ciImage, forKey: cacheKey)
                return ciImage
            } else {
                return nil
            }
        }
    }
}

// MARK: - Private types

private final class CacheKey: NSObject {
    let size: CGSize
    let orientation: CGImagePropertyOrientation

    init(size: CGSize, orientation: CGImagePropertyOrientation) {
        self.size = size
        self.orientation = orientation
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? CacheKey else {
            return false
        }
        return size == other.size && orientation == other.orientation
    }

    override var hash: Int {
        return size.width.hashValue ^ size.height.hashValue ^ orientation.hashValue
    }
}
