import AVFoundation
import PexipScreenCapture

/// ``MediaConnectionFactory`` provides factory methods
/// to create media connection, audio and video tracks, etc.
public protocol MediaConnectionFactory {
    /// Creates a new local audio track.
    func createLocalAudioTrack() -> LocalAudioTrack

    /*
     Creates a new camera video track for the best available camera.

     Best available camera is determined by the following order:
     1. First front-facing camera
     2. First back-facing camera
     3. The default video device
     */
    func createCameraVideoTrack() -> CameraVideoTrack?

    /**
     Creates a new camera track.
     - Parameters:
        - device: A physical device that provides realtime input video data.
     - Returns: A new camera track
     */
    func createCameraVideoTrack(device: AVCaptureDevice) -> CameraVideoTrack

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

    /**
     Create a new instance of ``MediaConnection`` type.
     - Parameters:
        - config: media connection config
     - Returns: A new instance of ``MediaConnection``
     */
    func createMediaConnection(config: MediaConnectionConfig) -> MediaConnection
}
