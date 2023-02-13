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

import CoreImage
import PexipCore

public typealias VideoFilter = PexipCore.VideoFilter

/// ``VideoFilterFactory`` provides factory methods to create video filters.
public struct VideoFilterFactory {
    private let ciContext: CIContext

    // MARK: - Init

    /// Creates a new instance of ``VideoFilterFactory``.
    public init() {
        let options: [CIContextOption: Any] = [
            .useSoftwareRenderer: false,
            .cacheIntermediates: false
        ]

        if let device = MTLCreateSystemDefaultDevice() {
            self.ciContext = CIContext(mtlDevice: device, options: options)
        } else {
            self.ciContext = CIContext(options: options)
        }
    }

    // MARK: - Public

    /**
     Creates a new segmentation video filter.

     - Parameters:
        - background: A filter that modifies the background of the video frame.
        - filters: An optional list of extra filters to apply on the whole video frame.

     - Returns: a new segmentation video filter.
     */
    @available(iOS 15.0, *)
    @available(macOS 12.0, *)
    public func segmentation(
        background: Background,
        filters: [CIFilter] = []
    ) -> VideoFilter {
        segmentation(
            segmenter: VisionPersonSegmenter(),
            background: background,
            filters: filters
        )
    }

    /**
     Creates a new segmentation video filter.

     - Parameters:
        - segmenter: A custom image buffer segmenter
        - background: A filter that modifies the background of the video frame.
        - filters: An optional list of extra filters to apply on the whole video frame.

     - Returns: a new segmentation video filter.
     */
    public func segmentation(
        segmenter: PersonSegmenter,
        background: Background,
        filters: [CIFilter] = []
    ) -> VideoFilter {
        let backgroundFilter: ImageFilter

        switch background {
        case .gaussianBlur(let radius):
            backgroundFilter = GaussianBlurFilter(radius: radius)
        case .tentBlur(let intensity):
            backgroundFilter = AccelerateBlurFilter(
                kind: .tent,
                intensity: intensity,
                ciContext: ciContext
            )
        case .boxBlur(let intensity):
            backgroundFilter = AccelerateBlurFilter(
                kind: .box,
                intensity: intensity,
                ciContext: ciContext
            )
        case .image(let image):
            backgroundFilter = ImageReplacementFilter(image: image)
        case .video(let url):
            backgroundFilter = VideoReplacementFilter(url: url)
        case .custom(let filter):
            backgroundFilter = CustomImageFilter(ciFilter: filter)
        }

        return SegmentationVideoFilter(
            segmenter: segmenter,
            backgroundFilter: backgroundFilter,
            globalFilters: filters,
            ciContext: ciContext
        )
    }

    /**
     Creates a new custom video filter from the given instance of CIFilter.
     - Parameters:
        - ciFilter: A custom image filter
     - Returns: a new custom video filter
     */
    public func customFilter(_ ciFilter: CIFilter) -> VideoFilter {
        CustomVideoFilter(ciFilter: ciFilter, ciContext: ciContext)
    }
}

// MARK: - Background filters

public extension VideoFilterFactory {
    /// Built-in background filters.
    enum Background {
        /// Applies a Gaussian blur filter to the background of every video frame.
        /// - Parameter radius: The blur intensity (0...100)
        case gaussianBlur(radius: Float = 40)

        /// Applies a tent blur filter to the background of every video frame.
        /// - Parameter intensity: The blur intensity (0...1)
        case tentBlur(intensity: Float = 0.4)

        /// Applies a box blur filter to the background of every video frame.
        /// - Parameter intensity: The blur intensity (0...1)
        case boxBlur(intensity: Float = 0.4)

        /// Sets the given image as a background of your video content.
        /// - Parameter image: The virtual background image.
        case image(CGImage)

        /// Sets the given video as a background of your video content.
        /// - Parameter url: The url to a video file
        case video(url: URL)

        /// Applies the given CIFilter to the background of every video frame.
        /// - Parameter filter: A custom image filter
        case custom(filter: CIFilter)
    }
}
