import AVFoundation

/// ``MediaConnectionFactory`` provides factory methods
/// to create media connection, audio and video tracks, etc.
public protocol MediaConnectionFactory {
    /// Creates a new local audio track.
    func createLocalAudioTrack() -> LocalAudioTrack

    /// Creates a new local video track.
    func createCameraVideoTrack() -> CameraVideoTrack?

    /**
     Creates a new camera track.
     - Parameters:
        - device: A physical device that provides realtime input video data.
     - Returns: A new camera track
     */
    func createCameraVideoTrack(device: AVCaptureDevice) -> CameraVideoTrack

    #if os(macOS)
    /**
     Creates a new screen video track.
     - Parameters:
        - videoSource: The source of the screen content (display or window).
     - Returns: A new screen video track
     */
    func createScreenVideoTrack(videoSource: ScreenVideoSource) -> ScreenVideoTrack
    #endif

    /**
     Create a new instance of ``MediaConnection`` type.
     - Parameters:
        - config: media connection config
     - Returns: A new instance of ``MediaConnection``
     */
    func createMediaConnection(config: MediaConnectionConfig) -> MediaConnection
}
