/// A helper type that groups the video track with its content mode.
public struct Video {
    /// The video track.
    public let track: VideoTrack
    /// The content mode of the video.
    public let contentMode: VideoContentMode

    /**
     Creates a new instance of ``Video``.
     - Parameters:
        - track: The video track
        - contentMode: Indicates whether the view should fit or fill the parent context
     */
    public init(track: VideoTrack, contentMode: VideoContentMode) {
        self.track = track
        self.contentMode = contentMode
    }

    /**
     Creates a new instance of ``Video``.
     - Parameters:
        - track: The video track
        - qualityProfile: The quality profile of the video
     */
    public init(track: VideoTrack, qualityProfile: QualityProfile) {
        self.init(track: track, contentMode: .fitQualityProfile(qualityProfile))
    }
}
