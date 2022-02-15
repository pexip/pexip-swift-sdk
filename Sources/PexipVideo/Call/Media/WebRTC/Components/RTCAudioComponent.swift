import WebRTC

final class RTCAudioComponent: AudioComponent {
    var isMuted = false {
        didSet(value) {
            track.isEnabled = value
        }
    }

    private weak var trackManager: RTCTrackManager?
    private let track: RTCAudioTrack
    private let audioSession = RTCAudioSession.sharedInstance()
    private let audioQueue = DispatchQueue(label: "audio")
    private var trackSender: RTCRtpSender?

    // MARK: - Init

    init(
        factory: RTCPeerConnectionFactory,
        trackManager: RTCTrackManager,
        streamId: String
    ) {
        let audioSource = factory.audioSource(with: .empty)
        self.track = factory.audioTrack(with: audioSource, trackId: UUID().uuidString)
        self.trackSender = trackManager.add(track, streamIds: [streamId])
        self.trackManager = trackManager

        configureAudioSession()
    }

    deinit {
        cleanResources()
    }

    // MARK: - Internal methods

    func speakerOn() {
        overrideOutputAudioPort(.speaker)
    }

    func speakerOff() {
        overrideOutputAudioPort(.none)
    }

    private func cleanResources() {
        if let trackSender = trackSender {
            _ = trackManager?.removeTrack(trackSender)
        }
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
