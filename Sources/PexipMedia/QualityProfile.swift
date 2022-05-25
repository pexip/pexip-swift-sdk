import CoreGraphics
import CoreMedia

/// Call quality profile.
public struct QualityProfile: Hashable {
    public static let `default` = Self.high

    /// 1280x720 (16:9)
    public static let high = QualityProfile(
        width: 1280,
        height: 720,
        fps: 30,
        bandwidth: 1280,
        opusBitrate: 64
    )

    #if os(iOS)

    /// 1920x1080 (16:9)
    public static let veryHigh = QualityProfile(
        width: 1920,
        height: 1080,
        fps: 30,
        bandwidth: 2880,
        opusBitrate: 64
    )

    /// 960x540 (16:9)
    public static let medium = QualityProfile(
        width: 960,
        height: 540,
        fps: 25,
        bandwidth: 768
    )

    /// 480x360 (4:3)
    public static let low = QualityProfile(
        width: 480,
        height: 360,
        fps: 15,
        bandwidth: 384
    )

    #else

    /// 640x480 (4:3)
    public static let medium = QualityProfile(
        width: 640,
        height: 480,
        fps: 30,
        bandwidth: 768
    )

    #endif

    /// The width of a video stream (640...1920)
    public let width: UInt
    /// The height of a video stream (360...1080)
    public let height: UInt
    /// The FPS of a video stream (1...60)
    public let fps: UInt
    /// The max bandwidth of a video stream (384...2560)
    public let bandwidth: UInt
    /// An optional bitrate of an OPUS audio stream (64...510)
    public private(set) var opusBitrate: UInt?
    /// The aspect ratio of a video stream
    public var aspectRatio: CGSize {
        CGSize(width: Int(width), height: Int(height))
    }

    // MARK: - Init

    /**
     Call quality profile.

     - Parameters:
        - width: the width of a video stream (640...1920)
        - height: the height of a video stream (360...1080)
        - fps: the FPS of a video stream (1...60)
        - bandwidth: the max bandwidth of a video stream (384...2560)
        - opusBitrate: an optional bitrate of an OPUS audio stream (64...510)
     */
    public init(
        width: UInt,
        height: UInt,
        fps: UInt,
        bandwidth: UInt,
        opusBitrate: UInt? = nil
    ) {
        precondition((480...1920).contains(width))
        precondition((360...1080).contains(height))
        precondition((1...60).contains(fps))
        precondition((384...2880).contains(bandwidth))

        if let opusBitrate = opusBitrate {
            precondition((64...510).contains(opusBitrate))
        }

        self.width = width
        self.height = height
        self.fps = fps
        self.bandwidth = bandwidth
        self.opusBitrate = opusBitrate
    }

    // MARK: - Frame rate

    /**
     Selects best frame rate for this quality profile
     from the provided array of frame rate ranges, typically [AVFrameRateRange].

     - Parameters:
        - frameRateRanges: Frame rate ranges
        - maxFrameRate: A key path to access the max frame rate
                        of the range (e.g. \AVFrameRateRange.maxFrameRate)
     - Returns: Best frame rate
     */
    public func bestFrameRate<T>(
        from frameRateRanges: [T],
        maxFrameRate: KeyPath<T, Float64>
    ) -> Float64? {
        let targetFrameRate = Float64(fps)
        var selectedFrameRate: Float64?
        var currentDiff = Float64.greatestFiniteMagnitude

        for frameRateRange in frameRateRanges {
            let maxFrameRate = frameRateRange[keyPath: maxFrameRate]
            let diff = abs(maxFrameRate - targetFrameRate)
            if diff < currentDiff {
                selectedFrameRate = maxFrameRate
                currentDiff = diff
            }
        }

        return selectedFrameRate.map {
            Swift.min($0, targetFrameRate)
        }
    }

    /**
     Selects best format from the provided array of formats,
     typically [AVCaptureDevice.Format].

     - Parameters:
        - formats: Capture device formats
        - formatDescription: A key path to access the formatDescription of the format
                             (e.g. \AVCaptureDevice.Format.formatDescription)
     - Returns: Best frame rate
     */
    public func bestFormat<T>(
        from formats: [T],
        formatDescription: KeyPath<T, CMFormatDescription>
    ) -> T? {
        let targetWidth = Int32(width)
        let targetHeight = Int32(height)
        var selectedFormat: T?
        var currentDiff = Int32.max

        for format in formats {
            let dimension = CMVideoFormatDescriptionGetDimensions(
                format[keyPath: formatDescription]
            )
            let widthDiff = abs(targetWidth - dimension.width)
            let heightDiff = abs(targetHeight - dimension.height)

            let diff = widthDiff + heightDiff
            if diff < currentDiff {
                selectedFormat = format
                currentDiff = Int32(diff)
            }
        }

        return selectedFormat
    }
}
