import Foundation
import os.log
import PexipUtils

public extension DefaultLogger {
    /// Default logger for PexipConference framework
    static let conference = DefaultLogger(
        logContainer: OSLog(
            subsystem: Bundle(
                for: InfinityConference.self
            ).bundleIdentifier!,
            category: "conference"
        )
    )
}
