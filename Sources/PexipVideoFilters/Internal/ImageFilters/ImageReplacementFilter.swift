import Foundation
import CoreImage

final class ImageReplacementFilter: ImageFilter {
    private let customImage: CGImage
    private var imageCache = NSCache<CacheKey, CIImage>()

    // MARK: - Init

    init(image: CGImage) {
        self.customImage = image
    }

    deinit {
        imageCache.removeAllObjects()
    }

    // MARK: - ImageFilter

    func processImage(
        _ image: CIImage,
        withSize size: CGSize,
        orientation: CGImagePropertyOrientation
    ) -> CIImage? {
        let cacheKey = CacheKey(size: size, orientation: orientation)

        if let cachedImage = imageCache.object(forKey: cacheKey) {
            return cachedImage
        } else {
            if let cgImage = customImage.scaledToFill(size) {
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
