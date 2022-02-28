import XCTest
@testable import PexipVideo

final class TaskSleepTests: XCTestCase {
    func testSleep() async throws {
        let task = Task<TimeInterval, Error> {
            let date = Date()
            try await Task.sleep(seconds: 0.1)
            return Date().timeIntervalSince(date)
        }

        let timeInterval = try await task.value
        XCTAssertTrue(timeInterval > 0.1 && timeInterval < 0.2)
    }

    func testSleepWithInvalidSeconds() async throws {
        let task = Task<String, Error> {
            try await Task.sleep(seconds: 0)
            return "test"
        }

        do {
            _ = try await task.value
        } catch {
            XCTAssertTrue(error is CancellationError)
        }
    }
}
