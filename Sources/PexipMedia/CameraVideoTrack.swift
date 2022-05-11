import AVFoundation

public protocol CameraVideoTrack: LocalVideoTrack {
    func startCapture(profile: QualityProfile) async throws

    #if os(iOS)
    @discardableResult
    func toggleCamera() async throws -> AVCaptureDevice.Position
    #endif
}
