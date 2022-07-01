import WebRTC
import ImageIO
import PexipMedia
import PexipUtils

final class WebRTCVideoProcessor: NSObject, RTCVideoCapturerDelegate {
    var videoFilter = Synchronized<VideoFilter?>(nil)
    private let videoSource: RTCVideoSource

    // MARK: - Init

    init(videoSource: RTCVideoSource) {
        self.videoSource = videoSource
    }

    // MARK: - RTCVideoCapturerDelegate

    func capturer(_ capturer: RTCVideoCapturer, didCapture frame: RTCVideoFrame) {
        var rtcVideoFrame = frame

        defer {
            videoSource.capturer(capturer, didCapture: rtcVideoFrame)
        }

        guard let videoFilter = videoFilter.value else {
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
