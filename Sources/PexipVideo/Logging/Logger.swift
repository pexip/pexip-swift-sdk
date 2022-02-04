import os.log

// MARK: - Protocol

/// An object for writing string messages to the logging system of choice.
public protocol LoggerProtocol {
    /// Sends a message to the logging system
    ///
    /// - Parameter message: The message you want to log
    /// - Parameter category: A category to group related log messages
    /// - Parameter level: The log level to assign to the message
    func log(_ message: String, category: LogCategory, level: LogLevel)
}

// MARK: - Internal helpers

extension LoggerProtocol {
    subscript(_ category: LogCategory) -> CategoryLogger {
        CategoryLogger.make(withCategory: category, logger: self)
    }
}

struct CategoryLogger {
    // Use factory method to hide properties
    // and exclude init method from autocompletion
    static func make(
        withCategory category: LogCategory,
        logger: LoggerProtocol
    ) -> CategoryLogger {
        CategoryLogger(category: category, logger: logger)
    }

    private let category: LogCategory
    private let logger: LoggerProtocol

    func debug(_ message: String) {
        logger.log(message, category: category, level: .debug)
    }

    func info(_ message: String) {
        logger.log(message, category: category, level: .info)
    }

    func warn(_ message: String) {
        logger.log(message, category: category, level: .warn)
    }

    func error(_ message: String) {
        logger.log(message, category: category, level: .error)
    }
}

// MARK: - Implementation

public struct DefaultLogger: LoggerProtocol {
    public init() {}

    var onLog: ((String) -> Void)?

    public func log(_ message: String, category: LogCategory, level: LogLevel) {
        let logContainer = OSLog.logContainer(for: category)
        let message = "\(level.rawValue) \(message)"

        os_log("%@", log: logContainer, type: level.osLogType, message)
        onLog?(message)
    }
}

// MARK: - Private extensions

private extension OSLog {
    static let subsystem = Bundle(for: Conference.self).bundleIdentifier!

    static let auth = OSLog(subsystem: subsystem, category: LogCategory.auth.rawValue)
    static let sse = OSLog(subsystem: subsystem, category: LogCategory.sse.rawValue)
    static let conference = OSLog(subsystem: subsystem, category: LogCategory.conference.rawValue)
    static let dnsLookup = OSLog(subsystem: subsystem, category: LogCategory.dnsLookup.rawValue)
    static let http = OSLog(subsystem: subsystem, category: LogCategory.http.rawValue)

    static func logContainer(for category: LogCategory) -> OSLog {
        switch category {
        case .auth:
            return .auth
        case .sse:
            return .sse
        case .conference:
            return .conference
        case .dnsLookup:
            return .dnsLookup
        case .http:
            return .http
        }
    }
}

private extension LogLevel {
    var osLogType: OSLogType {
        switch self {
        case .debug:
            return .debug
        case .info, .warn:
            return .info
        case .error:
            return .error
        }
    }
}
