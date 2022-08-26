#if os(iOS)

import XCTest
import Combine
import CoreMedia
@testable import PexipScreenCapture

final class BroadcastSampleHandlerTests: XCTestCase {
    private let appGroup = "test"
    private let fileManager = BroadcastFileManagerMock()
    private let notificationCenter = BroadcastNotificationCenter.default
    private var userDefaults: UserDefaults!
    private var handler: BroadcastSampleHandler!
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        userDefaults = UserDefaults(suiteName: appGroup)
        userDefaults.broadcastFps = nil

        handler = BroadcastSampleHandler(
            appGroup: appGroup,
            fileManager: fileManager
        )
    }

    override func tearDown() {
        notificationCenter.removeObserver(self)
        handler = nil
        userDefaults.removePersistentDomain(forName: appGroup)
        super.tearDown()
    }

    // MARK: - Tests

    func testInitWithHigherFps() {
        userDefaults.broadcastFps = 30
        handler = BroadcastSampleHandler(
            appGroup: appGroup,
            fileManager: fileManager
        )

        XCTAssertEqual(handler.fps, 15)
    }

    func testInitWithLowerFps() {
        let fps: UInt = 5

        userDefaults.broadcastFps = fps
        handler = BroadcastSampleHandler(
            appGroup: appGroup,
            fileManager: fileManager
        )

        XCTAssertEqual(handler.fps, fps)
    }

    func testBroadcastStarted() {
        let expectation = self.expectation(description: "Broadcast started")

        notificationCenter.addObserver(self, for: .broadcastStarted, using: {
            expectation.fulfill()
        })
        handler.broadcastStarted()

        wait(for: [expectation], timeout: 0.1)
    }

    func testBroadcastPaused() {
        let expectation = self.expectation(description: "Broadcast paused")

        notificationCenter.addObserver(self, for: .broadcastPaused, using: {
            expectation.fulfill()
        })
        handler.broadcastPaused()

        wait(for: [expectation], timeout: 0.1)
    }

    func testBroadcastResumed() {
        let expectation = self.expectation(description: "Broadcast resumed")

        notificationCenter.addObserver(self, for: .broadcastResumed, using: {
            expectation.fulfill()
        })
        handler.broadcastResumed()

        wait(for: [expectation], timeout: 0.1)
    }

    func testBroadcastFinished() {
        let expectation = self.expectation(description: "Broadcast finished")

        notificationCenter.addObserver(self, for: .broadcastFinished, using: {
            expectation.fulfill()
        })
        handler.broadcastFinished()

        wait(for: [expectation], timeout: 0.1)
    }

    func testDidFinishWithError() throws {
        let expectation = self.expectation(description: "Did finish with error")

        let filePath = fileManager.broadcastSocketPath(appGroup: appGroup)
        let server = try BroadcastServer(filePath: filePath)
        let client = BroadcastClient(filePath: filePath)
        let delegate = BroadcastSampleHandlerDelegateMock()

        handler = BroadcastSampleHandler(client: client, fps: 15)
        handler.delegate = delegate

        server.sink { [weak self] httpEvent in
            guard let self = self else {
                return
            }

            switch httpEvent {
            case .start:
                self.notificationCenter.post(.serverStarted)
            default:
                break
            }
        }.store(in: &cancellables)

        client.sink { httpEvent in
            switch httpEvent {
            case .connect:
                try? server.stop()
            case .stop:
                break
            }
        }.store(in: &cancellables)

        delegate.onError = { error in
            switch error as? BroadcastError {
            case .broadcastFinished(let error):
                XCTAssertNotNil(error)
                expectation.fulfill()
            default:
                break
            }
        }

        handler.broadcastStarted()
        try server.start()

        wait(for: [expectation], timeout: 0.3)
    }

    func testProcessSampleBuffer() throws {
        let messageExpectation = self.expectation(description: "Message received")

        let filePath = fileManager.broadcastSocketPath(appGroup: appGroup)
        let server = try BroadcastServer(filePath: filePath)
        let client = BroadcastClient(filePath: filePath)
        let width = 1920
        let height = 1080
        let sampleBuffer = CMSampleBuffer.stub(width: width, height: height)

        handler = BroadcastSampleHandler(client: client, fps: 15)

        client.sink { [weak self] httpEvent in
            guard let self = self else {
                return
            }

            switch httpEvent {
            case .connect:
                XCTAssertFalse(self.handler.processSampleBuffer(sampleBuffer, with: .audioApp))
                XCTAssertFalse(self.handler.processSampleBuffer(sampleBuffer, with: .audioMic))
                XCTAssertFalse(
                    self.handler.processSampleBuffer(sampleBuffer, with: .init(rawValue: 100)!)
                )
                XCTAssertTrue(self.handler.processSampleBuffer(sampleBuffer, with: .video))
            case .stop:
                break
            }
        }.store(in: &cancellables)

        server.sink { [weak self] httpEvent in
            guard let self = self else {
                return
            }

            switch httpEvent {
            case .start:
                self.notificationCenter.post(.serverStarted)
            case .message(let message):
                XCTAssertEqual(message.header.videoWidth, UInt32(width))
                XCTAssertEqual(message.header.videoHeight, UInt32(height))
                messageExpectation.fulfill()
            case .stop:
                break
            }
        }.store(in: &cancellables)

        handler.broadcastStarted()
        try server.start()

        wait(for: [messageExpectation], timeout: 0.3)
    }

    func testProcessSampleBufferWhenClientNotConnected() throws {
        XCTAssertFalse(handler.processSampleBuffer(.stub(), with: .video))
    }
}

// MARK: - Mocks

final class BroadcastFileManagerMock: FileManager {
    var fileError: Error?

    override func fileExists(atPath path: String) -> Bool {
        return fileError != nil ? true : super.fileExists(atPath: path)
    }

    override func removeItem(atPath path: String) throws {
        if let error = fileError {
            throw error
        } else {
            try super.removeItem(atPath: path)
        }
    }

    override func containerURL(
        forSecurityApplicationGroupIdentifier groupIdentifier: String
    ) -> URL? {
        return URL(string: "/tmp")
    }
}

private final class BroadcastSampleHandlerDelegateMock: BroadcastSampleHandlerDelegate {
    var onError: ((Error) -> Void)?

    func broadcastSampleHandler(
        _ handler: BroadcastSampleHandler,
        didFinishWithError error: Error
    ) {
        onError?(error)
    }
}

#endif
