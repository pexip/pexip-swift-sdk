import CoreGraphics
/// Call quality profile.
public struct QualityProfile: Hashable {
    /// 1920x1080 (16:9)
    public static let veryHigh = QualityProfile(
        width: 1920,
        height: 1080,
        fps: 30,
        bandwidth: 2880,
        opusBitrate: 64
    )

    /// 1280x720 (16:9)
    public static let high = QualityProfile(
        width: 1280,
        height: 720,
        fps: 30,
        bandwidth: 1280,
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
}
