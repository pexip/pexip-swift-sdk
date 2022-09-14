import os.log

// MARK: - Types

@frozen
public enum LogLevel: String, CaseIterable {
    case debug = "🟣"
    case info = "🟢"
    case warn = "🟡"
    case error = "🔴"
}

// MARK: - Protocol

public protocol Logger {
    func log(_ message: String, level: LogLevel)
}

public extension Logger {
    func debug(_ message: String) {
        log(message, level: .debug)
    }

    func info(_ message: String) {
        log(message, level: .info)
    }

    func warn(_ message: String) {
        log(message, level: .warn)
    }

    func error(_ message: String) {
        log(message, level: .error)
    }
}

// MARK: - Default implementation

public struct DefaultLogger: Logger {
    private let logContainer: OSLog
    var onLog: ((String) -> Void)?

    public init(logContainer: OSLog) {
        self.logContainer = logContainer
    }

    public func log(_ message: String, level: LogLevel) {
        let message = "\(level.rawValue) \(message)"
        os_log("%@", log: logContainer, type: level.osLogType, message)
        onLog?(message)
    }
}

// MARK: - Private types

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
