//
// Copyright 2024 Pexip AS
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

import AVFoundation
import Foundation

/// An object that represents an audio frame.
@frozen
public struct AudioFrame {
    public let streamDescription: AudioStreamBasicDescription
    public let data: Data

    public var isSignedInteger: Bool {
        (streamDescription.mFormatFlags & kAudioFormatFlagIsSignedInteger) != 0
    }

    public var isFloat: Bool {
        (streamDescription.mFormatFlags & kAudioFormatFlagIsFloat) != 0
    }

    public var isInterleaved: Bool {
        (streamDescription.mFormatFlags & kAudioFormatFlagIsNonInterleaved) == 0
    }

    // MARK: - Init

    public init(
        streamDescription: AudioStreamBasicDescription,
        data: Data
    ) {
        self.streamDescription = streamDescription
        self.data = data
    }
}
