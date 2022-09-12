import AVFoundation

/// ``CameraVideoTrackFactory`` provides factory methods to create video tracks.
public protocol CameraVideoTrackFactory {
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
}
