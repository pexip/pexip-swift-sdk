/// An identifier for various media features (send/receive video/audio)
public struct MediaFeature: OptionSet {
    public let rawValue: Int

    /**
     Creates a media feature with a raw int value.
     - Parameters:
        - rawValue: A raw int value.
     */
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// Send audio.
    public static let sendAudio = MediaFeature(rawValue: 1 << 0)
    /// Send video.
    public static let sendVideo = MediaFeature(rawValue: 1 << 1)
    /// Receive audio.
    public static let receiveAudio = MediaFeature(rawValue: 1 << 2)
    /// Receive video.
    public static let receiveVideo = MediaFeature(rawValue: 1 << 3)
    // All media features.
    public static let all: MediaFeature = [.sendAudio, .sendVideo, .receiveAudio, .receiveVideo]
}
