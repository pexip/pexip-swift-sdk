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
            self = .up
        case ._90:
            self = .left
        case ._270:
            self = .right
        case ._180:
            self = .down
        @unknown default:
            self = .up
        }
    }
}
