public struct MediaFeature: OptionSet {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let sendAudio = MediaFeature(rawValue: 1 << 0)
    public static let sendVideo = MediaFeature(rawValue: 1 << 1)
    public static let receiveAudio = MediaFeature(rawValue: 1 << 2)
    public static let receiveVideo = MediaFeature(rawValue: 1 << 3)

    public static let all: MediaFeature = [.sendAudio, .sendVideo, .receiveAudio, .receiveVideo]
}
