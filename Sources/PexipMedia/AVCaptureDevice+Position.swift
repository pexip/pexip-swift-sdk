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

    static func videoCaptureDevice(
        withPosition position: AVCaptureDevice.Position
    ) -> AVCaptureDevice? {
        videoCaptureDevices(withPosition: position).first
    }
}
