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
import ImageIO
import PexipMedia
import PexipCore
import PexipScreenCapture

// MARK: - WebRTCScreenCapturerDelegate

protocol WebRTCScreenCapturerDelegate: AnyObject {
    #if os(iOS)
    func webRTCScreenCapturerDidStart(_ capturer: WebRTCScreenCapturer)
    #endif

    func webRTCScreenCapturer(
        _ capturer: WebRTCScreenCapturer,
        didStopWithError error: Error?
    )
}

// MARK: - WebRTCScreenCapturer

final class WebRTCScreenCapturer: RTCVideoCapturer, ScreenMediaCapturerDelegate {
    weak var capturerDelegate: WebRTCScreenCapturerDelegate?

    private let videoSource: RTCVideoSource
    private let capturer: ScreenMediaCapturer
    private let logger: Logger?
    private var videoProfile: QualityProfile
    private var startTimeNs: UInt64?

    // MARK: - Init

    init(
        videoSource: RTCVideoSource,
        mediaCapturer: ScreenMediaCapturer,
        defaultVideoProfile: QualityProfile,
        logger: Logger?
    ) {
        self.videoSource = videoSource
        self.capturer = mediaCapturer
        self.videoProfile = defaultVideoProfile
        self.logger = logger
        super.init(delegate: videoSource)
        capturer.delegate = self
    }

    // MARK: - Capture

    func startCapture(withVideoProfile videoProfile: QualityProfile) async throws {
        self.videoProfile = videoProfile
        try await capturer.startCapture(
            atFps: videoProfile.fps,
            outputDimensions: videoProfile.dimensions
        )
    }

    func stopCapture(reason: ScreenCaptureStopReason?) async throws {
        try await capturer.stopCapture(reason: reason)
        logger?.info("Screen capture did stop.")
    }

    // MARK: - ScreenMediaCapturerDelegate

    func screenMediaCapturer(
        _ capturer: ScreenMediaCapturer,
        didCaptureVideoFrame videoFrame: VideoFrame
    ) {
        let cropDimensions = videoFrame.contentDimensions
        let adaptedDimensions = videoFrame.adaptedContentDimensions(
            to: videoProfile.dimensions
        )

        videoSource.adaptOutputFormat(
            toWidth: adaptedDimensions.width,
            height: adaptedDimensions.height,
            fps: Int32(videoProfile.fps)
        )

        let rtcPixelBuffer = RTCCVPixelBuffer(
            pixelBuffer: videoFrame.pixelBuffer,
            adaptedWidth: adaptedDimensions.width,
            adaptedHeight: adaptedDimensions.height,
            cropWidth: cropDimensions.width,
            cropHeight: cropDimensions.height,
            cropX: videoFrame.contentX,
            cropY: videoFrame.contentY
        )

        startTimeNs = startTimeNs ?? videoFrame.displayTimeNs

        let rtcVideoFrame = RTCVideoFrame(
            buffer: rtcPixelBuffer.toI420(),
            rotation: videoFrame.orientation.rtcRotation,
            timeStampNs: Int64(videoFrame.displayTimeNs - startTimeNs!)
        )

        delegate?.capturer(self, didCapture: rtcVideoFrame)
    }

    #if os(iOS)

    func screenMediaCapturerDidStart(_ capturer: ScreenMediaCapturer) {
        logger?.info("Screen capture did start.")
        capturerDelegate?.webRTCScreenCapturerDidStart(self)
    }

    #endif

    func screenMediaCapturer(
        _ capturer: ScreenMediaCapturer,
        didStopWithError error: Error?
    ) {
        capturerDelegate?.webRTCScreenCapturer(self, didStopWithError: error)
    }
}
