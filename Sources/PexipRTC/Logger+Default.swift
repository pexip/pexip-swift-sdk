import os.log
import Foundation
import PexipUtils

public extension DefaultLogger {
    static let mediaWebRTC = DefaultLogger(
        logContainer: OSLog(
            subsystem: Bundle(
                for: WebRTCMediaConnection.self
            ).bundleIdentifier!,
            category: "webrtc"
        )
    )
}
