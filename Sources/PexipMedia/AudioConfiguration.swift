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

public struct AudioConfiguration: Equatable {
    public let category: AVAudioSession.Category
    public let mode: AVAudioSession.Mode
    public let options: AVAudioSession.CategoryOptions

    // MARK: - Init

    public init(
        category: AVAudioSession.Category,
        mode: AVAudioSession.Mode,
        options: AVAudioSession.CategoryOptions
    ) {
        self.category = category
        self.mode = mode
        self.options = options
    }
}

// MARK: - Presets

public extension AudioConfiguration {
    static let idle = AudioConfiguration(
        category: .ambient,
        mode: .default,
        options: []
    )

    static let call = AudioConfiguration(
        category: .playAndRecord,
        mode: .voiceChat,
        options: [
            .allowBluetooth,
            .allowBluetoothA2DP,
            .defaultToSpeaker
        ]
    )

    static let screenCapture = AudioConfiguration(
        category: .playAndRecord,
        mode: .voiceChat,
        options: [
            .mixWithOthers
        ]
    )
}

#endif
