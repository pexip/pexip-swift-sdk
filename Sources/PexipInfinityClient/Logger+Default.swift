import Foundation
import os.log
import PexipCore

public extension DefaultLogger {
    /// Default logger for PexipInfinityClient framework
    static let infinityClient = DefaultLogger(
        logContainer: OSLog(
            subsystem: Bundle(
                for: HTTPEventSourceParser.self
            ).bundleIdentifier!,
            category: "conference"
        )
    )
}
