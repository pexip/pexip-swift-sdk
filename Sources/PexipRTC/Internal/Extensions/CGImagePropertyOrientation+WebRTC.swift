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

    init(rtcRotation: RTCVideoRotation) {
        switch rtcRotation {
        case ._0:
            self = .right
        case ._90:
            self = .up
        case ._270:
            self = .down
        case ._180:
            self = .left
        @unknown default:
            self = .right
        }
    }
}
