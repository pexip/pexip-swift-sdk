import os.log
import Foundation
import PexipCore

public extension DefaultLogger {
    /// Default logger for PexipRTC framework
    static let mediaWebRTC = DefaultLogger(
        logContainer: OSLog(
            subsystem: Bundle(
                for: WebRTCMediaConnection.self
            ).bundleIdentifier!,
            category: "webrtc"
        )
    )
}
