import Foundation
import os.log
import PexipUtils

public extension DefaultLogger {
    static let infinityClient = DefaultLogger(
        logContainer: OSLog(
            subsystem: Bundle(
                for: EventStreamParser.self
            ).bundleIdentifier!,
            category: "conference"
        )
    )
}
