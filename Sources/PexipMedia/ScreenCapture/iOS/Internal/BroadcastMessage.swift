#if os(iOS)

import Foundation
import CoreMedia

struct BroadcastMessage {
    let header: BroadcastHeader
    let body: Data
}

// MARK: - CMSampleBuffer

extension BroadcastMessage {
    init?(sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = sampleBuffer.imageBuffer else {
            return nil
        }

        guard let data = pixelBuffer.data else {
            return nil
        }

        let header = BroadcastHeader(
            displayTimeNs: sampleBuffer.displayTimeNs,
            pixelFormat: pixelBuffer.pixelFormat,
            videoWidth: pixelBuffer.width,
            videoHeight: pixelBuffer.height,
            videoOrientation: sampleBuffer.videoOrientation,
            contentLength: UInt32(data.count)
        )

        self.init(header: header, body: data)
    }
}

#endif
