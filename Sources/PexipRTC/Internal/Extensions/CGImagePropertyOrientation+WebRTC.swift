import ImageIO
import WebRTC

extension CGImagePropertyOrientation {
    var rtcRotation: RTCVideoRotation {
        switch self {
        case .up, .upMirrored, .down, .downMirrored:
            return ._0
        case .left, .leftMirrored:
            return ._90
        case .right, .rightMirrored:
            return ._270
        default:
            return ._0
        }
    }
}
