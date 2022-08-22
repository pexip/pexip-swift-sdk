#if os(iOS)

import XCTest
@testable import PexipScreenCapture

final class FileManagerBroadcastTests: XCTestCase {
    func testBroadcastSocketPath() {
        let fileManager = FileManager.default
        let path = fileManager.broadcastSocketPath(appGroup: "Test")

        XCTAssertTrue(path.hasSuffix("pex_broadcast_FD"))
    }

    func testBroadcastSocketPathWithNoContainerURL() {
        let fileManager = FileManagerMock()
        let path = fileManager.broadcastSocketPath(appGroup: "Test")

        XCTAssertEqual(path, "pex_broadcast_FD")
    }
}

// MARK: - Mocks

final class FileManagerMock: FileManager {
    override func containerURL(
        forSecurityApplicationGroupIdentifier groupIdentifier: String
    ) -> URL? {
        return nil
    }
}

#endif
