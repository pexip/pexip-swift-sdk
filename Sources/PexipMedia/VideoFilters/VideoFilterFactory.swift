import CoreImage

/// ``VideoFilterFactory`` provides factory methods to create video filters.
public struct VideoFilterFactory {
    private let ciContext: CIContext
    private let segmenter: PersonSegmenter

    /// Creates a new instance of ``VideoFilterFactory``
    /// with default ``PersonSegmenter``.
    @available(iOS 15.0, *)
    @available(macOS 12.0, *)
    public init() {
        self.init(segmenter: VisionPersonSegmenter())
    }

    /**
     Creates a new instance of ``VideoFilterFactory``.

     - Parameters:
        - segmenter: A custom image buffer segmenter
     */
    public init(segmenter: PersonSegmenter) {
        let options: [CIContextOption: Any] = [
            .useSoftwareRenderer: false,
            .cacheIntermediates: false
        ]

        self.segmenter = segmenter

        if let device = MTLCreateSystemDefaultDevice() {
            self.ciContext = CIContext(mtlDevice: device, options: options)
        } else {
            self.ciContext = CIContext(options: options)
        }
    }

    // MARK: - Public

    /**
     Creates a new filter that applies a Gaussian blur filter to video frames.

     - Parameters:
        - radius: The blur intensity (0...100)
        - segmenter: A custom image buffer segmenter
        - ciContext: A custom CoreImage context
     - Returns: A new video filter
     */
    public func gaussianBlur(radius: Float = 40) -> VideoFilter {
        GaussianBlurFilter(radius: radius, segmenter: segmenter, ciContext: ciContext)
    }

    /**
     Creates a new filter that applies a tent blur filter to video frames.

     - Parameters:
        - intensity: The blur intensity (0...1)
     - Returns: A new video filter
     */
    public func tentBlur(intensity: Float = 0.4) -> VideoFilter {
        AccelerateBlurFilter(
            kind: .tent,
            intensity: intensity,
            segmenter: segmenter,
            ciContext: ciContext
        )
    }

    /**
     Creates a new filter that applies a box blur filter to video frames.

     - Parameters:
        - intensity: The blur intensity (0...1)
     - Returns: A new video filter
     */
    public func boxBlur(intensity: Float = 0.4) -> VideoFilter {
        AccelerateBlurFilter(
            kind: .box,
            intensity: intensity,
            segmenter: segmenter,
            ciContext: ciContext
        )
    }

    /**
     Sets the given image as a background of your video content.

     - Parameters:
        - image: The virtual background image
     - Returns: A new video filter
     */
    public func virtualBackground(image: CGImage) -> VideoFilter {
        ImageBackgroundFilter(
            backgroundImage: image,
            segmenter: segmenter,
            ciContext: ciContext
        )
    }

    /**
     Sets the given video as a background of your video content.

     - Parameters:
        - videoURL: A url to a video file
     - Returns: A new video filter
     */
    public func virtualBackground(videoURL: URL) -> VideoFilter {
        VideoBackgroundFilter(
            url: videoURL,
            segmenter: segmenter,
            ciContext: ciContext
        )
    }
}
