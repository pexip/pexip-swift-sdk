import AVFoundation

/// A local camera video track.
public protocol CameraVideoTrack: LocalMediaTrack, VideoTrack {
    /**
     Starts the capture.

     - Parameters:
        - videoProfile: The video ``QualityProfile``
     */
    func startCapture(withVideoProfile videoProfile: QualityProfile) async throws

    #if os(iOS)
    /// Toggles between local camera devices,
    /// from front-facing to back-facing camera.
    @discardableResult
    func toggleCamera() async throws -> AVCaptureDevice.Position
    #endif
}
