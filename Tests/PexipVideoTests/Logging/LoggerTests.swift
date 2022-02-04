import XCTest
@testable import PexipVideo

final class LoggerTests: XCTestCase {
    private var logger: LoggerMock!

    // MARK: - Init

    override func setUp() {
        super.setUp()
        logger = LoggerMock()
    }

    // MARK: - Tests

    func testDefaultLogger() {
        var logger = DefaultLogger()
        var loggedMessage: String?

        logger.onLog = {
            loggedMessage = $0
        }

        for level in LogLevel.allCases {
            logger.log("Test", category: .conference, level: level)
            XCTAssertEqual(loggedMessage, "\(level.rawValue) Test")
        }
    }

    func testCategoryLogger() {
        for category in LogCategory.allCases {
            logger[category].debug("Message")
            XCTAssertEqual(logger.message, "Message")
            XCTAssertEqual(logger.category, category)
            XCTAssertEqual(logger.level, .debug)
        }
    }

    func testDebug() {
        logger[.auth].debug("Debug")
        XCTAssertEqual(logger.level, .debug)
    }

    func testInfo() {
        logger[.auth].info("Info")
        XCTAssertEqual(logger.level, .info)
    }

    func testWarn() {
        logger[.auth].warn("Warning")
        XCTAssertEqual(logger.level, .warn)
    }

    func testError() {
        logger[.auth].error("Error")
        XCTAssertEqual(logger.level, .error)
    }
}
