import Foundation
import os.log
import PexipUtils

public extension DefaultLogger {
    static let infinityClient = DefaultLogger(
        logContainer: OSLog(
            subsystem: Bundle(
                for: EventSourceParser.self
            ).bundleIdentifier!,
            category: "conference"
        )
    )
}
