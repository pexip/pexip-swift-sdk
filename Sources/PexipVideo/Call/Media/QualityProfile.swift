/// Call quality profile.
public struct CallQualityProfile {
    public static let veryHigh = CallQualityProfile(
        width: 1920,
        height: 1080,
        fps: 30,
        bandwidth: 2880,
        opusBitrate: 64
    )

    public static let high = CallQualityProfile(
        width: 1280,
        height: 720,
        fps: 30,
        bandwidth: 1280,
        opusBitrate: 64
    )

    public static let medium = CallQualityProfile(
        width: 720,
        height: 480,
        fps: 25,
        bandwidth: 768
    )

    public static let low = CallQualityProfile(
        width: 640,
        height: 360,
        fps: 15,
        bandwidth: 384
    )

    /// The width of a video stream (640..1920)
    public let width: Int
    /// The height of a video stream (360..1080)
    public let height: Int
    /// The FPS of a video stream (1..60)
    public let fps: Int
    /// The max bandwidth of a video stream (384..2560)
    public let bandwidth: UInt
    /// An optional bitrate of an OPUS audio stream (64..510)
    public private(set) var opusBitrate: Int?
}
