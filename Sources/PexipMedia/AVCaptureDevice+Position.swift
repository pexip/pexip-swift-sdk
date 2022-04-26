import AVFoundation

public extension AVCaptureDevice {
    static func videoCaptureDevice(
        withPosition position: AVCaptureDevice.Position
    ) -> AVCaptureDevice? {
        AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: position
        ).devices.first
    }
}
