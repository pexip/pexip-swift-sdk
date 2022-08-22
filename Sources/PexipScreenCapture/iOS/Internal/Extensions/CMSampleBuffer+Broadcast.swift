#if os(iOS)

import Foundation
import CoreMedia
import ReplayKit

extension CMSampleBuffer {
    var videoOrientation: UInt32 {
        let value = CMGetAttachment(
            self,
            key: RPVideoSampleOrientationKey as CFString,
            attachmentModeOut: nil
        )
        return value?.uint32Value ?? CGImagePropertyOrientation.up.rawValue
    }
}

#endif
