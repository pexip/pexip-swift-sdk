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

import WebRTC
import ImageIO
import PexipMedia
import PexipCore

final class WebRTCVideoProcessor: NSObject, RTCVideoCapturerDelegate {
    var videoFilter: VideoFilter? {
        videoFilterLock.lock()
        defer { videoFilterLock.unlock() }
        return _videoFilter
    }

    private var _videoFilter: VideoFilter?
    private let videoFilterLock = NSLock()
    private let videoSource: RTCVideoSource

    // MARK: - Init

    init(videoSource: RTCVideoSource) {
        self.videoSource = videoSource
    }

    // MARK: - Internal

    func setVideoFilter(_ videoFilter: VideoFilter?) {
        videoFilterLock.lock()
        _videoFilter = videoFilter
        videoFilterLock.unlock()
    }

    // MARK: - RTCVideoCapturerDelegate

    func capturer(_ capturer: RTCVideoCapturer, didCapture frame: RTCVideoFrame) {
        var rtcVideoFrame = frame

        defer {
            videoSource.capturer(capturer, didCapture: rtcVideoFrame)
        }

        guard let videoFilter else {
            return
        }

        guard let buffer = frame.buffer as? RTCCVPixelBuffer else {
            return
        }

        let orientation = CGImagePropertyOrientation(rtcRotation: frame.rotation)

        let pixelBuffer = videoFilter.processPixelBuffer(
            buffer.pixelBuffer,
            orientation: orientation
        )

        let rtcPixelBuffer = RTCCVPixelBuffer(pixelBuffer: pixelBuffer)

        rtcVideoFrame = RTCVideoFrame(
            buffer: rtcPixelBuffer.toI420(),
            rotation: frame.rotation,
            timeStampNs: frame.timeStampNs
        )
    }
}
