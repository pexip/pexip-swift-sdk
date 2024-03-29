//
// Copyright 2023 Pexip AS
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

import AVFoundation
import PexipCore

public protocol AudioSessionConfigurator: AnyObject {
    var isActive: Bool { get async }
    var configuration: AudioConfiguration? { get async }
    func activate(for configuration: AudioConfiguration) async
    func deactivate() async
    func speakerOn() async
    func speakerOff() async
}

public actor AudioSession: AudioSessionConfigurator {
    @available(*, deprecated, renamed: "AudioSession.init")
    public static let shared = AudioSession(logger: DefaultLogger.media)

    public var isActive = false
    public var configuration: AudioConfiguration?

    private let audioSession: AVAudioSession
    private let logger: Logger?

    // MARK: - Init

    public init(
        audioSession: AVAudioSession = AVAudioSession.sharedInstance(),
        logger: Logger? = nil
    ) {
        self.audioSession = audioSession
        self.logger = logger
    }

    // MARK: - Public

    public func activate(for configuration: AudioConfiguration) {
        do {
            try setActive(true, configuration: configuration)
        } catch {
            logger?.error("Error activating AVAudioSession: \(error)")
        }
    }

    public func deactivate() {
        do {
            try setActive(false, configuration: .idle)
        } catch {
            logger?.error("Error deactivating AVAudioSession: \(error)")
        }
    }

    public func speakerOn() {
        overrideOutputAudioPort(.speaker)
    }

    public func speakerOff() {
        overrideOutputAudioPort(.none)
    }

    // MARK: - Private

    private func setActive(
        _ isActive: Bool,
        configuration: AudioConfiguration
    ) throws {
        try audioSession.setCategory(
            configuration.category,
            mode: configuration.mode,
            options: configuration.options
        )
        if self.isActive != isActive {
            try audioSession.setActive(isActive, options: .notifyOthersOnDeactivation)
        }
        self.isActive = isActive
        self.configuration = configuration
    }

    private func overrideOutputAudioPort(_ port: AVAudioSession.PortOverride) {
        do {
            try self.audioSession.overrideOutputAudioPort(port)
        } catch {
            logger?.error("Error overriding AVAudioSession output audio port: \(error)")
        }
    }
}

#endif
