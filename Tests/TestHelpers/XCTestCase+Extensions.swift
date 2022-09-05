import XCTest
import MachO

public extension XCTestCase {
    static let snapshotName: String = {
        #if os(iOS)
        let platform = "iOS"
        #else
        let platform = "macOS"
        #endif

        #if arch(x86_64)
            return "\(platform)_x86_64"
        #else
            return platform
        #endif
    }()

    var snapshotName: String {
        Self.snapshotName
    }

    func wait(
        for operation: (XCTestExpectation) -> Void,
        after: () -> Void,
        timeout: TimeInterval = 0.3
    ) {
        let expectation = expectation(description: "Test expectation")
        operation(expectation)

        after()
        wait(for: [expectation], timeout: timeout)
    }
}
