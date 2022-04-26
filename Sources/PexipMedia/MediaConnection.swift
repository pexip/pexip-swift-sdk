import AVFoundation

public protocol MediaConnection {
    var isCapturingMainVideo: Bool { get }
    var isAudioMuted: Bool { get }

    func sendMainAudio()
    func sendMainVideo()

    func startMainCapture() async throws
    func startMainCapture(with device: AVCaptureDevice) async throws
    func stopMainCapture() async throws
    #if os(iOS)
    func toggleMainCaptureCamera() async throws
    #endif

    func muteAudio(_ muted: Bool)

    func start() async throws
    func stop() async
}
