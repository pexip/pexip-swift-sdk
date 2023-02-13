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

import CoreGraphics
import ImageIO

// MARK: - CGImage

extension CGImage {
    func scaledToFill(_ targetSize: CGSize) -> CGImage? {
        let size = CGSize(
            width: width,
            height: height
        ).aspectFillSize(for: targetSize)

        let context = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: 0,
            space: colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: bitmapInfo.rawValue
        )
        context?.interpolationQuality = .default
        context?.draw(self, in: CGRect(origin: .zero, size: size))

        let scaledImage = context?.makeImage()

        let cropRect = CGRect(
            x: (size.width - targetSize.width) / 2,
            y: (size.height - targetSize.height) / 2,
            width: targetSize.width,
            height: targetSize.height
        )

        return scaledImage?.cropping(to: cropRect)
    }
}

// MARK: - CGSize

extension CGSize {
    func aspectFillSize(for targetSize: CGSize) -> CGSize {
        var targetSize = targetSize
        let wRatio = targetSize.width / width
        let hRatio = targetSize.height / height

        if hRatio > wRatio {
            targetSize.width = hRatio * width
        } else if wRatio > hRatio {
            targetSize.height = wRatio * height
        }

        return targetSize
    }
}

// MARK: - CGImagePropertyOrientation

extension CGImagePropertyOrientation {
    var isVertical: Bool {
        switch self {
        case .up, .upMirrored, .down, .downMirrored:
            return true
        default:
            return false
        }
    }
}
