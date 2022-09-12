import PexipScreenCapture

/// ``MediaConnectionFactory`` provides factory methods to create screen media tracks.
public protocol ScreenMediaTrackFactory {
    #if os(iOS)

    /**
     Creates a new screen media track.
     - Parameters:
        - appGroup: The app group identifier.
        - broadcastUploadExtension: Bundle identifier of your broadcast upload extension.
     - Returns: A new screen media track
     */
    func createScreenMediaTrack(
        appGroup: String,
        broadcastUploadExtension: String
    ) -> ScreenMediaTrack

    #else

    /**
     Creates a new screen media track.
     - Parameters:
        - mediaSource: The source of the screen content (display or window).
     - Returns: A new screen media track
     */
    func createScreenMediaTrack(mediaSource: ScreenMediaSource) -> ScreenMediaTrack

    #endif
}
