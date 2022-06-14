/// The max bandwidth of a video stream (512...6144)
public struct Bandwidth: RawRepresentable, Hashable {
    /// The max bandwidth of a video stream.
    public let rawValue: UInt

    /**
     Creates a new instance of ``Bandwidth``.

     - Parameters:
        - rawValue: the max bandwidth of a video stream (512...6144)
     */
    public init?(rawValue: UInt) {
        if (512...6144).contains(rawValue) {
            self.rawValue = rawValue
        } else {
            return nil
        }
    }

    // MARK: - Default values

    /// Up to 512 kbps
    public static let low = Bandwidth(rawValue: 512)!

    /// Up to 1264 kbps
    public static let medium = Bandwidth(rawValue: 1264)!

    /// Up to 2464 kbps
    public static let high = Bandwidth(rawValue: 2464)!

    /// Up to 6144 kbps
    public static let veryHigh = Bandwidth(rawValue: 6144)!
}
