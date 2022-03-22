@testable import PexipVideo

final class LoggerMock: LoggerProtocol {
    private(set) var message = ""
    private(set) var category: LogCategory?
    private(set) var level: LogLevel?

    func log(_ message: String, category: LogCategory, level: LogLevel) {
        self.message = message
        self.category = category
        self.level = level
    }
}

// MARK: - Stubs

extension CategoryLogger {
    static let stub = CategoryLogger.make(
        withCategory: .conference,
        logger: LoggerMock()
    )
}
