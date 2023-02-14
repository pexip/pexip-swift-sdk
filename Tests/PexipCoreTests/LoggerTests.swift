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
import XCTest
@testable import PexipCore

final class LoggerTests: XCTestCase {
    private var logger: LoggerMock!

    // MARK: - Init

    override func setUp() {
        super.setUp()
        logger = LoggerMock()
    }

    // MARK: - Tests

    func testDefaultLogger() {
        var logger = DefaultLogger(
            logContainer: OSLog(
                subsystem: Bundle(for: LoggerTests.self).bundleIdentifier!,
                category: "conference"
            )
        )
        var loggedMessage: String?

        logger.onLog = { message in
            loggedMessage = message
        }

        for level in LogLevel.allCases {
            logger.log("Test", level: level)
            XCTAssertEqual(loggedMessage, "\(level.rawValue) Test")
        }
    }

    func testLogLevel() {
        XCTAssertEqual(LogLevel.debug.rawValue, "🟣")
        XCTAssertEqual(LogLevel.info.rawValue, "🟢")
        XCTAssertEqual(LogLevel.warn.rawValue, "🟡")
        XCTAssertEqual(LogLevel.error.rawValue, "🔴")
    }

    func testDebug() {
        logger.debug("Debug")
        XCTAssertEqual(logger.message, "Debug")
        XCTAssertEqual(logger.level, .debug)
    }

    func testInfo() {
        logger.info("Info")
        XCTAssertEqual(logger.message, "Info")
        XCTAssertEqual(logger.level, .info)
    }

    func testWarn() {
        logger.warn("Warning")
        XCTAssertEqual(logger.message, "Warning")
        XCTAssertEqual(logger.level, .warn)
    }

    func testError() {
        logger.error("Error")
        XCTAssertEqual(logger.message, "Error")
        XCTAssertEqual(logger.level, .error)
    }
}

// MARK: - Mocks

private final class LoggerMock: PexipCore.Logger {
    private(set) var message: String?
    private(set) var level: LogLevel?

    func log(_ message: String, level: LogLevel) {
        self.message = message
        self.level = level
    }
}
