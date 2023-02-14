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
import PexipScreenCapture

final class WebRTCScreenMediaTrack: WebRTCVideoTrack,
                                    ScreenMediaTrack,
                                    WebRTCScreenCapturerDelegate {
    let capturingStatus = CapturingStatus(isCapturing: false)
    private let capturer: WebRTCScreenCapturer
    private let defaultVideoProfile: QualityProfile

    // MARK: - Init

    init(
        rtcTrack: RTCVideoTrack,
        capturer: WebRTCScreenCapturer,
        defaultVideoProfile: QualityProfile = .presentationHigh
    ) {
        self.capturer = capturer
        self.defaultVideoProfile = defaultVideoProfile
        super.init(rtcTrack: rtcTrack)
        capturer.capturerDelegate = self
    }

    deinit {
        stopCapture(withDelay: false, reason: nil)
    }

    // MARK: - ScreenMediaTrack

    func startCapture() async throws {
        try await startCapture(withVideoProfile: defaultVideoProfile)
    }

    func startCapture(withVideoProfile videoProfile: QualityProfile) async throws {
        if capturingStatus.isCapturing {
            stopCapture()
        }

        try await capturer.startCapture(withVideoProfile: videoProfile)

        #if os(macOS)
        setIsCapturing(true)
        #endif
    }

    func stopCapture() {
        stopCapture(reason: nil)
    }

    func stopCapture(reason: ScreenCaptureStopReason?) {
        stopCapture(withDelay: true, reason: reason)
    }

    // MARK: - WebRTCScreenCapturerDelegate

    #if os(iOS)

    func webRTCScreenCapturerDidStart(_ capturer: WebRTCScreenCapturer) {
        setIsCapturing(true)
    }

    #endif

    func webRTCScreenCapturer(
        _ capturer: WebRTCScreenCapturer,
        didStopWithError error: Error?
    ) {
        setIsCapturing(false)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.renderEmptyFrame()
        }
    }

    // MARK: - Private

    private func setIsCapturing(_ isCapturing: Bool) {
        isEnabled = isCapturing
        capturingStatus.isCapturing = isCapturing
    }

    private func stopCapture(withDelay: Bool, reason: ScreenCaptureStopReason?) {
        guard capturingStatus.isCapturing else {
            return
        }

        setIsCapturing(false)

        func stop(capturer: WebRTCScreenCapturer?) {
            Task { [weak self, weak capturer] in
                try await capturer?.stopCapture(reason: reason)
                self?.renderEmptyFrame()
            }
        }

        if withDelay {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak capturer] in
                stop(capturer: capturer)
            }
        } else {
            stop(capturer: capturer)
        }
    }
}
