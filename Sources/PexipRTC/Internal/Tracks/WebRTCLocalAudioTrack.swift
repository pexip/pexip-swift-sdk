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

import WebRTC
import PexipMedia
import PexipCore

final class WebRTCLocalAudioTrack: WebRTCLocalTrack, LocalAudioTrack {
    let capturingStatus = CapturingStatus(isCapturing: false)
    let rtcTrack: RTCAudioTrack
    var streamMediaTrack: RTCMediaStreamTrack { rtcTrack }
    #if os(iOS)
    var audioSession: AudioSessionConfigurator?
    #endif
    private let permission: MediaCapturePermission
    private let logger: Logger?

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
        Task {
            await audioSession?.speakerOn()
        }
    }

    func speakerOff() {
        Task {
            await audioSession?.speakerOff()
        }
    }

    #endif
}
