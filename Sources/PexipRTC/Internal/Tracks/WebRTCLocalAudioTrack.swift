import WebRTC
import PexipMedia
import PexipCore

final class WebRTCLocalAudioTrack: LocalAudioTrack {
    let capturingStatus = CapturingStatus(isCapturing: false)
    let rtcTrack: RTCAudioTrack

    private let permission: MediaCapturePermission
    private let logger: Logger?

    #if os(iOS)
    private lazy var audioManager = AudioManager(logger: logger)
    #endif

    // MARK: - Init

    init(
        rtcTrack: RTCAudioTrack,
        permission: MediaCapturePermission = .audio,
        logger: Logger?
    ) {
        self.rtcTrack = rtcTrack
        self.permission = permission
        self.logger = logger
    }

    deinit {
        stopCapture()
    }

    // MARK: - LocalAudioTrack

    func startCapture() async throws {
        let status = await permission.requestAccess()

        if let error = MediaCapturePermissionError(status: status) {
            throw error
        }

        guard !capturingStatus.isCapturing else {
            return
        }

        rtcTrack.isEnabled = true
        capturingStatus.isCapturing = true
    }

    func stopCapture() {
        guard capturingStatus.isCapturing else {
            return
        }

        rtcTrack.isEnabled = false
        capturingStatus.isCapturing = false
    }

    #if os(iOS)

    func speakerOn() {
        audioManager.speakerOn()
    }

    func speakerOff() {
        audioManager.speakerOff()
    }

    #endif
}
