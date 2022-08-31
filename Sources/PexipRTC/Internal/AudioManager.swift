import PexipMedia
import WebRTC
import PexipCore

#if os(iOS)

final class AudioManager {
    private let logger: Logger?
    private let audioSession = RTCAudioSession.sharedInstance()
    private let audioQueue = DispatchQueue(label: "audio")

    // MARK: - Init

    init(logger: Logger?) {
        self.logger = logger
        configureAudioSession()
    }

    // MARK: - Internal

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
            try audioSession.setCategory(
                AVAudioSession.Category.playAndRecord.rawValue,
                with: [.mixWithOthers]
            )
            try audioSession.setMode(AVAudioSession.Mode.voiceChat.rawValue)
        } catch {
            logger?.error("Error changing AVAudioSession category: \(error)")
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
                try self.audioSession.setCategory(category, with: [.mixWithOthers])
                try self.audioSession.overrideOutputAudioPort(portOverride)
                try self.audioSession.setActive(true)
            } catch {
                self.logger?.error("Error setting AVAudioSession category: \(error)")
            }

            self.audioSession.unlockForConfiguration()
        }
    }
}

#endif
