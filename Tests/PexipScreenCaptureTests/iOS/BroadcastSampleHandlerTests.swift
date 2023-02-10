#if os(iOS)

import XCTest
import CoreMedia
@testable import PexipScreenCapture

final class BroadcastSampleHandlerTests: XCTestCase {
    private let appGroup = "test"
    private let filePath = NSTemporaryDirectory().appending("/test")
    private let fileManager = BroadcastFileManagerMock()
    private let notificationCenter = BroadcastNotificationCenter.default
    private var userDefaults: UserDefaults!
    private var handler: BroadcastSampleHandler!
    private var videoSender: BroadcastVideoSender!
    private var delegate: BroadcastSampleHandlerDelegateMock!

    // MARK: - Setup

    override func setUpWithError() throws {
        try super.setUpWithError()

        userDefaults = UserDefaults(suiteName: appGroup)
        userDefaults.broadcastFps = 15
        userDefaults.broadcastKeepAliveDate = Date()

        videoSender = BroadcastVideoSender(filePath: filePath)
        delegate = BroadcastSampleHandlerDelegateMock()
        handler = BroadcastSampleHandler(
            videoSender: videoSender,
            userDefaults: userDefaults
        )
        handler.delegate = delegate

        _ = try fileManager.createMappedFile(
            atPath: filePath,
            size: BroadcastVideoReceiver.maxFileSize
        )
    }

    override func tearDownWithError() throws {
        notificationCenter.removeObserver(self)
        handler = nil
        userDefaults.removePersistentDomain(forName: appGroup)
        try? fileManager.removeItem(atPath: filePath)
        try super.tearDownWithError()
    }

    // MARK: - Tests

    func testBroadcastStarted() {
        let expectation = self.expectation(description: "Sender started")

        notificationCenter.addObserver(self, for: .senderStarted, using: { [weak self] in
            XCTAssertTrue(self?.handler.isConnected == false)
            expectation.fulfill()
        })
        handler.broadcastStarted()

        wait(for: [expectation], timeout: 0.1)
    }

    func testBroadcastStartedWithOutdatedKeepAliveDate() {
        let timeInterval = TimeInterval(BroadcastScreenCapturer.keepAliveInterval * 6)
        let errorExpectation = self.expectation(description: "Error expectation")
        let finishExpectation = self.expectation(description: "Sender finished")

        notificationCenter.addObserver(self, for: .senderFinished, using: {
            finishExpectation.fulfill()
        })

        let delegate = BroadcastSampleHandlerDelegateMock()
        delegate.onError = { error in
            if (error as? BroadcastError) == .noConnection {
                errorExpectation.fulfill()
            }
        }

        handler.delegate = delegate
        userDefaults.broadcastKeepAliveDate = Date().addingTimeInterval(-timeInterval)
        handler.broadcastStarted()

        wait(for: [errorExpectation, finishExpectation], timeout: 0.3)
    }

    func testBroadcastStartedWithNoKeepAliveDate() {
        let errorExpectation = self.expectation(description: "Error expectation")
        let finishExpectation = self.expectation(description: "Sender finished")

        notificationCenter.addObserver(self, for: .senderFinished, using: {
            finishExpectation.fulfill()
        })

        let delegate = BroadcastSampleHandlerDelegateMock()
        delegate.onError = { error in
            if (error as? BroadcastError) == .noConnection {
                errorExpectation.fulfill()
            }
        }

        handler = BroadcastSampleHandler(appGroup: appGroup, fileManager: fileManager)
        handler.delegate = delegate
        userDefaults.broadcastKeepAliveDate = nil
        handler.broadcastStarted()

        wait(for: [errorExpectation, finishExpectation], timeout: 0.3)
    }

    func testBroadcastPaused() {
        let expectation = self.expectation(description: "Sender paused")

        notificationCenter.addObserver(self, for: .senderPaused, using: {
            expectation.fulfill()
        })
        handler.broadcastPaused()

        wait(for: [expectation], timeout: 0.1)
    }

    func testBroadcastResumed() {
        let expectation = self.expectation(description: "Sender resumed")

        notificationCenter.addObserver(self, for: .senderResumed, using: {
            expectation.fulfill()
        })
        handler.broadcastResumed()

        wait(for: [expectation], timeout: 0.1)
    }

    func testBroadcastFinished() {
        let expectation = self.expectation(description: "Sender finished")

        notificationCenter.addObserver(self, for: .senderFinished, using: {
            expectation.fulfill()
        })
        handler.broadcastFinished()

        wait(for: [expectation], timeout: 0.1)
    }

    func testReceiverStarted() throws {
        let expectation = self.expectation(description: "Receiver started")

        handler.broadcastStarted()
        notificationCenter.addObserver(self, for: .receiverStarted, using: { [weak self] in
            guard let self else { return }
            XCTAssertTrue(self.handler.isConnected)
            XCTAssertTrue(self.videoSender.isRunning)
            expectation.fulfill()
        })

        notificationCenter.post(.receiverStarted)

        wait(for: [expectation], timeout: 0.1)
    }

    func testReceiverStartedWithVideoSenderError() throws {
        let expectation = self.expectation(description: "Sender finished")

        videoSender = BroadcastVideoSender(filePath: "")
        handler = BroadcastSampleHandler(videoSender: videoSender, userDefaults: userDefaults)
        delegate.onError = { error in
            if (error as? BroadcastError) == .noConnection {
                expectation.fulfill()
            }
        }
        handler.delegate = delegate
        handler.broadcastStarted()
        notificationCenter.post(.receiverStarted)

        wait(for: [expectation], timeout: 0.1)
    }

    func testReceiverFinished() throws {
        let expectation = self.expectation(description: "Sender finished")

        delegate.onError = { [weak self] error in
            guard let self else { return }
            XCTAssertFalse(self.handler.isConnected)
            XCTAssertFalse(self.videoSender.isRunning)
            XCTAssertEqual(error as? BroadcastError, .broadcastFinished)
            expectation.fulfill()
        }
        startAndFinishWithNotification(.receiverFinished)

        wait(for: [expectation], timeout: 0.1)
    }

    func testCallEnded() throws {
        let expectation = self.expectation(description: "Call ended")

        delegate.onError = { [weak self] error in
            guard let self else { return }
            XCTAssertFalse(self.handler.isConnected)
            XCTAssertFalse(self.videoSender.isRunning)
            XCTAssertEqual(error as? BroadcastError, .callEnded)
            expectation.fulfill()
        }
        startAndFinishWithNotification(.callEnded)

        wait(for: [expectation], timeout: 0.1)
    }

    func testPresentationStolen() throws {
        let expectation = self.expectation(description: "Presentation stolen")

        delegate.onError = { [weak self] error in
            guard let self else { return }
            XCTAssertFalse(self.handler.isConnected)
            XCTAssertFalse(self.videoSender.isRunning)
            XCTAssertEqual(error as? BroadcastError, .presentationStolen)
            expectation.fulfill()
        }
        startAndFinishWithNotification(.presentationStolen)

        wait(for: [expectation], timeout: 0.1)
    }

    func testProcessSampleBuffer() throws {
        let expectation = self.expectation(description: "Video frame received")
        let receiverDelegate = BroadcastReceiverDelegateMock()
        let receiver = BroadcastVideoReceiver(filePath: filePath, fileManager: fileManager)
        let width = 1920
        let height = 1080
        let sampleBuffer = CMSampleBuffer.stub(width: width, height: height)

        handler.broadcastStarted()

        notificationCenter.addObserver(self, for: .receiverStarted, using: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                guard let self else { return }
                XCTAssertTrue(self.handler.processSampleBuffer(sampleBuffer, with: .video))
            }
        })

        receiverDelegate.onReceive = { videoFrame in
            XCTAssertEqual(videoFrame.width, UInt32(width))
            XCTAssertEqual(videoFrame.height, UInt32(height))
            expectation.fulfill()
        }

        receiver.delegate = receiverDelegate
        try receiver.start(withFps: BroadcastFps(value: 30))
        notificationCenter.post(.receiverStarted)

        wait(for: [expectation], timeout: 0.3)
    }

    func testProcessSampleBufferWhenClientNotConnected() throws {
        XCTAssertFalse(handler.processSampleBuffer(.stub(), with: .video))
    }

    func testProcessSampleBufferWhenNotValid() throws {
        let expectation = self.expectation(description: "Receiver started")

        handler.broadcastStarted()

        notificationCenter.addObserver(self, for: .receiverStarted, using: { [weak self] in
            guard let self else { return }

            let sampleBuffer = CMSampleBuffer.stub()
            try? sampleBuffer.invalidate()
            XCTAssertFalse(self.handler.processSampleBuffer(sampleBuffer, with: .video))
            expectation.fulfill()
        })

        notificationCenter.post(.receiverStarted)

        wait(for: [expectation], timeout: 0.1)
    }

    func testProcessSampleBufferWhenNotVideo() throws {
        let expectation = self.expectation(description: "Receiver started")

        handler.broadcastStarted()

        notificationCenter.addObserver(self, for: .receiverStarted, using: { [weak self] in
            guard let self else { return }

            XCTAssertFalse(self.handler.processSampleBuffer(.stub(), with: .audioApp))
            XCTAssertFalse(self.handler.processSampleBuffer(.stub(), with: .audioMic))
            XCTAssertFalse(self.handler.processSampleBuffer(.stub(), with: .init(rawValue: 1001)!))
            expectation.fulfill()
        })

        notificationCenter.post(.receiverStarted)

        wait(for: [expectation], timeout: 0.1)
    }

    func testDeinit() {
        let expectation = self.expectation(description: "Receiver started")

        handler.broadcastStarted()
        notificationCenter.addObserver(self, for: .receiverStarted, using: { [weak self] in
            guard let self else { return }
            XCTAssertTrue(self.handler.isConnected)
            XCTAssertTrue(self.videoSender.isRunning)
            expectation.fulfill()
        })

        notificationCenter.post(.receiverStarted)

        wait(for: [expectation], timeout: 0.1)
        handler = nil
        XCTAssertFalse(videoSender.isRunning)
    }

    // MARK: - Private

    private func startAndFinishWithNotification(_ notification: BroadcastNotification) {
        notificationCenter.addObserver(self, for: .receiverStarted, using: { [weak self] in
            self?.notificationCenter.post(notification)
        })
        handler.broadcastStarted()
        notificationCenter.post(.receiverStarted)
    }
}

// MARK: - Mocks

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
