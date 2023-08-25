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

final class WebRTCCameraVideoTrack: WebRTCVideoTrack, WebRTCLocalTrack, CameraVideoTrack {
    let capturingStatus = CapturingStatus(isCapturing: false)
    var streamMediaTrack: RTCMediaStreamTrack { rtcTrack }
    var videoProfile: QualityProfile?
    var videoFilter: VideoFilter? {
        didSet {
            processor.setVideoFilter(videoFilter)
        }
    }

    private var currentDevice: AVCaptureDevice
    private let processor: WebRTCVideoProcessor
    private let capturer: RTCCameraVideoCapturer
    private let permission: MediaCapturePermission

    // MARK: - Init

    init(
        device: AVCaptureDevice,
        rtcTrack: RTCVideoTrack,
        processor: WebRTCVideoProcessor,
        capturer: RTCCameraVideoCapturer,
        permission: MediaCapturePermission = .video
    ) {
        self.currentDevice = device
        self.processor = processor
        self.capturer = capturer
        self.permission = permission
        super.init(rtcTrack: rtcTrack)
    }

    deinit {
        stopCapture(withDelay: false)
    }

    // MARK: - CameraVideoTrack

    func startCapture() async throws {
        try await startCapture(withVideoProfile: .medium)
    }

    func startCapture(withVideoProfile videoProfile: QualityProfile) async throws {
        let status = await permission.requestAccess()

        if let error = MediaCapturePermissionError(status: status) {
            throw error
        }

        guard let format = videoProfile.bestFormat(
            from: RTCCameraVideoCapturer.supportedFormats(for: currentDevice),
            formatDescription: \.formatDescription
        ) else {
            return
        }

        guard let fps = videoProfile.bestFrameRate(
            from: format.videoSupportedFrameRateRanges,
            maxFrameRate: \.maxFrameRate
        ) else {
            return
        }

        isEnabled = true

        try await capturer.startCapture(
            with: currentDevice,
            format: format,
            fps: Int(fps)
        )

        self.videoProfile = videoProfile
        capturingStatus.isCapturing = true
    }

    func stopCapture() {
        stopCapture(withDelay: true)
    }

    #if os(iOS)
    func toggleCamera() async throws {
        guard let newDevice = AVCaptureDevice.videoCaptureDevices(
            withPosition: currentDevice.position == .front ? .back : .front
        ).first else {
            return
        }

        // Restart the video capturing using another camera
        currentDevice = newDevice

        if let videoProfile {
            try await startCapture(withVideoProfile: videoProfile)
        } else {
            try await startCapture()
        }
    }
    #endif

    // MARK: - Private

    private func stopCapture(withDelay: Bool) {
        guard capturingStatus.isCapturing else {
            return
        }

        isEnabled = false
        capturingStatus.isCapturing = false

        func stop(capturer: RTCCameraVideoCapturer?) {
            capturer?.stopCapture { [weak self] in
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
