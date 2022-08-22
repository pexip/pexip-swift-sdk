#if os(iOS)

import XCTest
import Combine
import CoreVideo
@testable import PexipScreenCapture

final class BroadcastClientTests: XCTestCase {
    private var client: BroadcastClient!
    private var server: BroadcastServer!
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Setup

    override func setUpWithError() throws {
        try super.setUpWithError()
        client = BroadcastClient(filePath: "test")
        server = try BroadcastServer(filePath: "test")
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        client?.stop()
        try server.stop()
        cancellables.removeAll()
    }

    // MARK: - Tests

    func testStart() throws {
        let expectation = self.expectation(description: "Start")

        client.sink { [unowned self] event in
            switch event {
            case .connect:
                XCTAssertTrue(self.client.isConnected)
                expectation.fulfill()
            case .stop:
                break
            }
        }.store(in: &cancellables)

        try server.start()
        XCTAssertTrue(client.start())

        wait(for: [expectation], timeout: 0.3)
    }

    func testStartWhenConnected() throws {
        try testStart()
        XCTAssertFalse(client.start())
    }

    func testStartWithoutServer() throws {
        let expectation = self.expectation(description: "Start without server")

        client.sink { [unowned self] event in
            switch event {
            case .connect:
                XCTFail("Invalid client event")
            case .stop(let error):
                XCTAssertTrue(error != nil)
                XCTAssertFalse(self.client.isConnected)
                expectation.fulfill()
            }
        }.store(in: &cancellables)

        client.start()

        wait(for: [expectation], timeout: 0.3)
    }

    func testStop() throws {
        try testStart()

        let expectation = self.expectation(description: "Stop")

        server.sink { event in
            switch event {
            case .stop(let error):
                XCTAssertTrue(error == nil)
                expectation.fulfill()
            case .message, .start:
                break
            }
        }.store(in: &cancellables)

        client.stop()

        wait(for: [expectation], timeout: 0.3)
    }

    func testStopOnDeinit() throws {
        try testStart()

        let expectation = self.expectation(description: "Stop")

        server.sink { event in
            switch event {
            case .stop(let error):
                XCTAssertTrue(error == nil)
                expectation.fulfill()
            case .message, .start:
                break
            }
        }.store(in: &cancellables)

        client = nil

        wait(for: [expectation], timeout: 0.3)
    }

    func testSendMessage() throws {
        // 1. Start the client and server.
        try testStart()

        // 2. Send a message.
        let message = try BroadcastMessage.creatStub()
        let sendExpectation = self.expectation(description: "Send message")

        server.sink { event in
            switch event {
            case .start, .stop:
                break
            case .message(let receivedMessage):
                XCTAssertEqual(message, receivedMessage)
                sendExpectation.fulfill()
            }
        }.store(in: &cancellables)

        Task {
            await client.send(message: message)
        }

        wait(for: [sendExpectation], timeout: 0.3)
    }

    func testSendMessageWhenNotConnected() throws {
        let message = try BroadcastMessage.creatStub()
        let sendExpectation = self.expectation(description: "Send message")

        Task {
            let result = await client.send(message: message)
            XCTAssertFalse(result)
            sendExpectation.fulfill()
        }

        wait(for: [sendExpectation], timeout: 0.3)
    }
}

// MARK: - Stubs

private extension BroadcastMessage {
    static func creatStub() throws -> BroadcastMessage {
        let time = MachAbsoluteTime(mach_absolute_time())
        let body = try XCTUnwrap("test".data(using: .utf8))
        return BroadcastMessage(
            header: BroadcastHeader(
                displayTimeNs: time.nanoseconds,
                pixelFormat: kCVPixelFormatType_32BGRA,
                videoWidth: 1920,
                videoHeight: 1080,
                videoOrientation: CGImagePropertyOrientation.up.rawValue,
                contentLength: UInt32(body.count)
            ),
            body: body
        )
    }
}

#endif
