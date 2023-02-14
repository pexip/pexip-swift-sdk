//
// Copyright 2022 Pexip AS
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

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
