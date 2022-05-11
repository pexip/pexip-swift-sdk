import Foundation
import os.log
import PexipUtils

public extension DefaultLogger {
    /// Default logger for PexipInfinityClient framework
    static let infinityClient = DefaultLogger(
        logContainer: OSLog(
            subsystem: Bundle(
                for: EventSourceParser.self
            ).bundleIdentifier!,
            category: "conference"
        )
    )
}
