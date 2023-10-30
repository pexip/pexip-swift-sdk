//
// Copyright 2022-2023 Pexip AS
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

#if os(iOS)

import WebRTC
import PexipCore
import PexipMedia

final actor WebRTCAudioSession: AudioSessionConfigurator {
    var isActive = false
    var configuration: AudioConfiguration?

    private var audioSession = RTCAudioSession.sharedInstance()
    private let logger: Logger?

    // MARK: - Init

    init(logger: Logger? = nil) {
        self.logger = logger
    }

    // MARK: - Public

    func activate(for configuration: AudioConfiguration) {
        do {
            try setActive(true, configuration: configuration)
        } catch {
            logger?.error("Error activating AVAudioSession: \(error)")
        }
    }

    func deactivate() {
        do {
            try setActive(false, configuration: .idle)
        } catch {
            logger?.error("Error deactivating AVAudioSession: \(error)")
        }
    }

    func speakerOn() {
        overrideOutputAudioPort(.speaker)
    }

    func speakerOff() {
        overrideOutputAudioPort(.none)
    }

    // MARK: - Private

    private func setActive(
        _ isActive: Bool,
        configuration: AudioConfiguration
    ) throws {
        audioSession.lockForConfiguration()

        let rtcConfiguration = RTCAudioSessionConfiguration.webRTC()
        rtcConfiguration.mode = configuration.mode.rawValue
        rtcConfiguration.category = configuration.category.rawValue
        rtcConfiguration.categoryOptions = configuration.options

        try audioSession.setConfiguration(rtcConfiguration)
        try audioSession.setActive(isActive)

        audioSession.unlockForConfiguration()

        self.isActive = isActive
        self.configuration = configuration
    }

    private func overrideOutputAudioPort(_ port: AVAudioSession.PortOverride) {
        do {
            audioSession.lockForConfiguration()
            try self.audioSession.overrideOutputAudioPort(port)
            audioSession.unlockForConfiguration()
        } catch {
            logger?.error("Error overriding AVAudioSession output audio port: \(error)")
        }
    }
}

#endif
