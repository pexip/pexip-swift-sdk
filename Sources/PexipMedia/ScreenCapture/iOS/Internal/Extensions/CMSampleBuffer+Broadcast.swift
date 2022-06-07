#if os(iOS)

import Foundation
import CoreMedia
import ReplayKit

// MARK: - Private extensions

extension CMSampleBuffer {
    var videoOrientation: UInt32 {
        let value = CMGetAttachment(
            self,
            key: RPVideoSampleOrientationKey as CFString,
            attachmentModeOut: nil
        )
        return value?.uint32Value ?? 0
    }

    var displayTimeNs: UInt64 {
        let displayTime = CMSampleBufferGetPresentationTimeStamp(self)
        let displayTimeNs = llround(
            CMTimeGetSeconds(displayTime) * Float64(NSEC_PER_SEC)
        )
        return UInt64(displayTimeNs)
    }
}

#endif
