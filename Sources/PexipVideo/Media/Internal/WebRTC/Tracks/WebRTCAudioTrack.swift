import WebRTC

final class WebRTCAudioTrack: LocalAudioTrackProtocol {
    private(set) var capturePermission: MediaCapturePermission
    private weak var trackManager: RTCTrackManager?
    private let track: RTCAudioTrack
    private let audioSession = RTCAudioSession.sharedInstance()
    private let audioQueue = DispatchQueue(label: "audio")
    private var trackSender: RTCRtpSender?

    // MARK: - Init

    init(
        factory: RTCPeerConnectionFactory,
        trackManager: RTCTrackManager,
        capturePermission: MediaCapturePermission,
        streamId: String
    ) {
        self.track = factory.audioTrack(withTrackId: UUID().uuidString)
        self.trackSender = trackManager.add(track, streamIds: [streamId])
        self.trackManager = trackManager
        self.capturePermission = capturePermission
        configureAudioSession()
    }

    deinit {
        if let trackSender = trackSender {
            _ = trackManager?.removeTrack(trackSender)
        }
    }

    // MARK: - Internal

    var isEnabled: Bool {
        track.isEnabled && capturePermission.isAuthorized
    }

    @MainActor
    @discardableResult
    func setEnabled(_ enabled: Bool) async -> Bool {
        guard isEnabled != enabled else {
            return isEnabled
        }

        track.isEnabled = enabled
        if enabled {
            await capturePermission.requestAccess(openSettingsIfNeeded: true)
        }

        return isEnabled
    }

    func speakerOn() {
        overrideOutputAudioPort(.speaker)
    }

    func speakerOff() {
        overrideOutputAudioPort(.none)
    }

    // MARK: - Private methods

    private func configureAudioSession() {
        audioSession.lockForConfiguration()

        do {
            try audioSession.setCategory(AVAudioSession.Category.playAndRecord.rawValue)
            try audioSession.setMode(AVAudioSession.Mode.voiceChat.rawValue)
        } catch let error {
            debugPrint("Error changing AVAudioSession category: \(error)")
        }

        audioSession.unlockForConfiguration()
    }

    private func overrideOutputAudioPort(_ portOverride: AVAudioSession.PortOverride) {
        audioQueue.async { [weak self] in
            guard let self = self else {
                return
            }

            self.audioSession.lockForConfiguration()

            do {
                let category = AVAudioSession.Category.playAndRecord.rawValue
                try self.audioSession.setCategory(category)
                try self.audioSession.overrideOutputAudioPort(portOverride)
                try self.audioSession.setActive(true)
            } catch let error {
                debugPrint("Error setting AVAudioSession category: \(error)")
            }

            self.audioSession.unlockForConfiguration()
        }
    }
}
