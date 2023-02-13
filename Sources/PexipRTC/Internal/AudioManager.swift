//
// Copyright 2022 Pexip AS
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

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
            guard let self else {
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
