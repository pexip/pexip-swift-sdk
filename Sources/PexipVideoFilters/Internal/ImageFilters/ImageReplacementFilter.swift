//
// Copyright 2022 Pexip AS
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

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
