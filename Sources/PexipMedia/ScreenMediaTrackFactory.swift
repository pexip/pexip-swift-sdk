import PexipScreenCapture

/// ``MediaConnectionFactory`` provides factory methods to create screen media tracks.
public protocol ScreenMediaTrackFactory {
    #if os(iOS)

    /**
     Creates a new screen media track.
     - Parameters:
        - appGroup: The app group identifier.
        - broadcastUploadExtension: Bundle identifier of your broadcast upload extension.
        - defaultVideoProfile: The default video quality profile to use
                               when screen capture starts automatically
                               (e.g. from the Control Center on iOS)
     - Returns: A new screen media track
     */
    func createScreenMediaTrack(
        appGroup: String,
        broadcastUploadExtension: String,
        defaultVideoProfile: QualityProfile
    ) -> ScreenMediaTrack

    #else

    /**
     Creates a new screen media track.
     - Parameters:
        - mediaSource: The source of the screen content (display or window).
        - defaultVideoProfile: The default video quality profile
     - Returns: A new screen media track
     */
    func createScreenMediaTrack(
        mediaSource: ScreenMediaSource,
        defaultVideoProfile: QualityProfile
    ) -> ScreenMediaTrack

    #endif
}
