import AVFoundation

public protocol CameraVideoTrack: LocalMediaTrack, VideoTrack {
    func startCapture(profile: QualityProfile) async throws

    #if os(iOS)
    @discardableResult
    func toggleCamera() async throws -> AVCaptureDevice.Position
    #endif
}
