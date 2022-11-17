import AVFoundation

public extension AVCaptureDevice {
    static func videoCaptureDevices(
        withPosition position: AVCaptureDevice.Position
    ) -> [AVCaptureDevice] {
        AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: position
        ).devices
    }
}
