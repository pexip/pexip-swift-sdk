#if os(iOS)

import XCTest
import Combine
import CoreVideo
import Network
@testable import PexipScreenCapture

final class BroadcastServerTests: XCTestCase {
    private let filePath = "test"
    private let fileManager = FileManager.default
    private var client: BroadcastClient!
    private var server: BroadcastServer!
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Setup

    override func setUpWithError() throws {
        try super.setUpWithError()
        client = BroadcastClient(filePath: filePath)
        server = try BroadcastServer(filePath: filePath)
    }

    override func tearDownWithError() throws {
        client?.stop()
        try server?.stop()
        cancellables.removeAll()
        try super.tearDownWithError()
    }

    // MARK: - Tests

    func testStart() throws {
        let expectation = self.expectation(description: "Start")

        server.sink { [weak self] event in
            guard let self = self else {
                return
            }

            switch event {
            case .start:
                XCTAssertTrue(self.server.isRunning)
                XCTAssertTrue(self.fileManager.fileExists(atPath: self.filePath))
                expectation.fulfill()
            case .message, .stop:
                break
            }
        }.store(in: &cancellables)

        XCTAssertTrue(try server.start())

        wait(for: [expectation], timeout: 0.1)
    }

    func testStartWhenRunning() throws {
        try testStart()
        XCTAssertFalse(try server.start())
        XCTAssertTrue(server.isRunning)
    }

    func testStartWithError() throws {
        let fileManager = BroadcastFileManagerMock()
        fileManager.fileError = URLError(.badURL)

        server = try BroadcastServer(
            filePath: filePath,
            fileManager: fileManager
        )

        XCTAssertThrowsError(try server.start()) { error in
            XCTAssertEqual((error as? URLError)?.code, .badURL)
        }
    }

    func testRejectMoreThanOneConnection() throws {
        let startExpectation = self.expectation(description: "Start")

        client.sink { [weak self] event in
            guard let self = self else {
                return
            }

            switch event {
            case .connect:
                XCTAssertTrue(self.client.isConnected)
                startExpectation.fulfill()
            case .stop:
                break
            }
        }.store(in: &cancellables)

        try server.start()
        XCTAssertTrue(client.start())

        wait(for: [startExpectation], timeout: 0.3)

        let rejectExpectation = self.expectation(description: "Reject")
        let endpoint = NWEndpoint.unix(path: filePath)
        let connection = NWConnection(to: endpoint, using: .tcp)

        connection.stateUpdateHandler = { state in
            switch state {
            case .failed:
                rejectExpectation.fulfill()
            default:
                break
            }
        }

        connection.start(queue: .main)
        wait(for: [rejectExpectation], timeout: 0.3)
    }

    func testStop() throws {
        try testStart()
        try server.stop()
        XCTAssertFalse(server.isRunning)
        XCTAssertFalse(fileManager.fileExists(atPath: filePath))
    }

    func testStopOnDeinit() throws {
        try testStart()
        server = nil
        XCTAssertFalse(fileManager.fileExists(atPath: filePath))
    }
}

#endif
