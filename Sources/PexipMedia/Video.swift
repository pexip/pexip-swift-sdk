public struct Video {
    /// The video track.
    public let track: VideoTrack
    /// The content mode of the video.
    public let contentMode: VideoContentMode

    /**
     - Parameters:
        - track: The video track
        - contentMode: Indicates whether the view should fit or fill the parent context
        - isMirrored: Indicates whether the video should be mirrored about its vertical axis
     */
    public init(track: VideoTrack, contentMode: VideoContentMode) {
        self.track = track
        self.contentMode = contentMode
    }

    /**
     - Parameters:
        - track: The video track
        - qualityProfile: The quality profile of the video
     */
    public init(track: VideoTrack, qualityProfile: QualityProfile) {
        self.init(track: track, contentMode: .fitQualityProfile(qualityProfile))
    }
}
