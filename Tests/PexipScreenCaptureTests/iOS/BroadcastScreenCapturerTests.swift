//
// Copyright 2022-2023 Pexip AS
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

#if os(iOS)

import XCTest
import CoreMedia
@testable import PexipScreenCapture

// swiftlint:disable type_body_length
final class BroadcastScreenCapturerTests: XCTestCase {
    private enum BroadcastState {
        case started, newFrame, stopped
    }

    private let appGroup = "test"
    private let notificationCenter = BroadcastNotificationCenter.default
    private var userDefaults: UserDefaults!
    private var fileManager: BroadcastFileManagerMock!
    private var delegate: ScreenMediaCapturerDelegateMock!
    private var capturer: BroadcastScreenCapturer!
    private var videoReceiver: BroadcastVideoReceiver!
    private let defaultFps: UInt = 15
    private let outputDimensions = CMVideoDimensions(width: 1280, height: 720)
    private var filePath: String {
        fileManager.broadcastVideoDataPath(appGroup: appGroup)
    }

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        userDefaults = UserDefaults(suiteName: appGroup)
        fileManager = BroadcastFileManagerMock()
        delegate = ScreenMediaCapturerDelegateMock()
        videoReceiver = BroadcastVideoReceiver(
            filePath: filePath,
            fileManager: fileManager
        )
        capturer = BroadcastScreenCapturer(
            broadcastUploadExtension: "test",
            defaultFps: defaultFps,
            videoReceiver: videoReceiver,
            keepAliveInterval: 0.1,
            userDefaults: userDefaults
        )
        capturer.delegate = delegate
    }

    override func tearDown() {
        notificationCenter.removeObserver(self)
        userDefaults.removePersistentDomain(forName: appGroup)
        capturer = nil
        fileManager.fileError = nil
        try? fileManager.removeItem(atPath: filePath)
        super.tearDown()
    }

    // MARK: - Tests

    func testDefaultFps() {
        XCTAssertEqual(userDefaults.broadcastFps, defaultFps)
    }

    func testKeepAliveTimer() {
        let expectation = self.expectation(description: "Keep alive date updated")
        let date = Date()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            let newDate = self?.userDefaults.broadcastKeepAliveDate
            if let distance = newDate?.distance(to: date) {
                XCTAssertEqual(distance, -0.2, accuracy: 0.1)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 0.3)
    }

    func testSenderStarted() {
        let senderExpectation = self.expectation(description: "Sender started")
        let receiverExpectation = self.expectation(description: "Receiver started")
        let delegateExpectation = self.expectation(description: "Delegate called")

        notificationCenter.addObserver(self, for: .senderStarted) { [weak self] in
            guard let self else { return }
            XCTAssertTrue(self.videoReceiver.isRunning)
            senderExpectation.fulfill()
            self.notificationCenter.removeObserver(self, for: .senderStarted)
            // Post `senderStarted` again to check that
            // it won't try to fulfill expectations twice
            self.notificationCenter.post(.senderStarted)
        }

        notificationCenter.addObserver(self, for: .receiverStarted) {
            receiverExpectation.fulfill()
        }

        delegate.onStart = {
            delegateExpectation.fulfill()
        }

        notificationCenter.post(.senderStarted)

        wait(for: [senderExpectation, receiverExpectation, delegateExpectation], timeout: 0.3)
    }

    func testSenderStartedWithError() {
        let delegateExpectation = self.expectation(description: "Delegate called")
        let receiverExpectation = self.expectation(description: "Receiver finished")

        notificationCenter.addObserver(self, for: .receiverFinished) {
            receiverExpectation.fulfill()
        }

        delegate.onStop = { [weak self] error in
            guard let self else { return }
            XCTAssertFalse(self.videoReceiver.isRunning)
            XCTAssertEqual(self.userDefaults?.broadcastFps, self.defaultFps)
            XCTAssertEqual(error as? BroadcastError, .noConnection)
            delegateExpectation.fulfill()
        }

        fileManager.fileError = BroadcastError.noConnection
        notificationCenter.post(.senderStarted)

        wait(for: [receiverExpectation, delegateExpectation], timeout: 0.1)
    }

    func testSenderFinished() {
        let delegateExpectation = self.expectation(description: "Delegate called")

        notificationCenter.addObserver(self, for: .senderStarted) { [weak self] in
            self?.notificationCenter.post(.senderFinished)
        }

        delegate.onStop = { [weak self] error in
            guard let self else { return }
            XCTAssertFalse(self.videoReceiver.isRunning)
            XCTAssertEqual(self.userDefaults?.broadcastFps, self.defaultFps)
            XCTAssertNil(error)
            delegateExpectation.fulfill()
        }

        notificationCenter.post(.senderStarted)

        wait(for: [delegateExpectation], timeout: 0.1)
    }

    func testSenderFinishedWithError() {
        let delegateExpectation = self.expectation(description: "Delegate called")

        notificationCenter.addObserver(self, for: .senderStarted) { [weak self] in
            self?.fileManager.fileError = BroadcastError.noConnection
            self?.notificationCenter.post(.senderFinished)
        }

        delegate.onStop = { [weak self] error in
            guard let self else { return }
            XCTAssertFalse(self.videoReceiver.isRunning)
            XCTAssertEqual(self.userDefaults?.broadcastFps, self.defaultFps)
            XCTAssertEqual(error as? BroadcastError, .noConnection)
            delegateExpectation.fulfill()
        }

        notificationCenter.post(.senderStarted)

        wait(for: [delegateExpectation], timeout: 0.1)
    }

    func testSenderFinishedWhenNotCapturing() {
        let delegateExpectation = self.expectation(description: "Delegate called")
        delegateExpectation.isInverted = true

        delegate.onStop = { _ in
            delegateExpectation.fulfill()
        }
        notificationCenter.post(.senderFinished)

        wait(for: [delegateExpectation], timeout: 0.1)
    }

    func testStartCapture() async throws {
        try await capturer.startCapture(atFps: 30)
        XCTAssertEqual(userDefaults.broadcastFps, 30)
    }

    func testStartCaptureWhenCapturing() async throws {
        // 1. Open broadcast extension dialogue
        try await capturer.startCapture(atFps: 25)
        XCTAssertEqual(userDefaults.broadcastFps, 25)

        // 2. Start receiver
        startReceiver()

        // 3. Try to start capture again
        try await capturer.startCapture(atFps: 15)

        // 4. Assert that there were no fps changes
        XCTAssertEqual(userDefaults.broadcastFps, 25)
    }

    func testStopCapture() throws {
        startReceiver()

        let expectation = self.expectation(description: "Receiver finished")
        notificationCenter.addObserver(self, for: .receiverFinished) {
            expectation.fulfill()
        }

        try capturer.stopCapture()
        wait(for: [expectation], timeout: 0.1)

        XCTAssertFalse(videoReceiver.isRunning)
        XCTAssertEqual(userDefaults?.broadcastFps, self.defaultFps)
        // Check that keep alive timer wasn't cancelled
        XCTAssertNotNil(userDefaults?.broadcastKeepAliveDate)
    }

    func testStopCaptureOnCallEnded() throws {
        startReceiver()

        let expectation = self.expectation(description: "Call ended")
        notificationCenter.addObserver(self, for: .callEnded) {
            expectation.fulfill()
        }

        try capturer.stopCapture(reason: .callEnded)
        wait(for: [expectation], timeout: 0.1)

        XCTAssertFalse(videoReceiver.isRunning)
        XCTAssertEqual(userDefaults?.broadcastFps, defaultFps)
        // Check that keep alive timer wasn't cancelled
        XCTAssertNotNil(userDefaults?.broadcastKeepAliveDate)
    }

    func testStopCaptureOnStolenPresentation() throws {
        startReceiver()

        let expectation = self.expectation(description: "Presentation stolen")
        notificationCenter.addObserver(self, for: .presentationStolen) {
            expectation.fulfill()
        }

        try capturer.stopCapture(reason: .presentationStolen)
        wait(for: [expectation], timeout: 0.1)

        XCTAssertFalse(videoReceiver.isRunning)
        XCTAssertEqual(userDefaults?.broadcastFps, defaultFps)
        // Check that keep alive timer wasn't cancelled
        XCTAssertNotNil(userDefaults?.broadcastKeepAliveDate)
    }

    func testStopCaptureWhenNotCapturing() throws {
        let expectation = self.expectation(description: "Receiver finished")
        expectation.isInverted = true
        notificationCenter.addObserver(self, for: .receiverFinished) {
            expectation.fulfill()
        }

        try capturer.stopCapture()
        wait(for: [expectation], timeout: 0.1)
    }

    // swiftlint:disable function_body_length
    func testBroadcast() throws {
        let startExpectation = self.expectation(description: "Broadcast started")
        let videoFrameExpectation = self.expectation(description: "Video frame received")
        let stopExpectation = self.expectation(description: "Broadcast finished")

        let width = 1920
        let height = 1080
        let sampleBuffer = CMSampleBuffer.stub(width: width, height: height, orientation: .left)
        let pixelBuffer = try XCTUnwrap(sampleBuffer.imageBuffer)
        let videoSender = BroadcastVideoSender(filePath: filePath, fileManager: fileManager)
        let handler = BroadcastSampleHandler(videoSender: videoSender, userDefaults: userDefaults)
        var states = [BroadcastState]()
        var videoFrameReceived = false

        delegate.onStart = {
            states.append(.started)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                XCTAssertTrue(handler.processSampleBuffer(sampleBuffer, with: .video))
                startExpectation.fulfill()
            }
        }

        delegate.onVideoFrame = { videoFrame in
            guard !videoFrameReceived else {
                return
            }

            videoFrameReceived = true
            states.append(.newFrame)

            XCTAssertEqual(videoFrame.orientation, .left)
            XCTAssertEqual(videoFrame.width, UInt32(width))
            XCTAssertEqual(videoFrame.height, UInt32(height))
            XCTAssertEqual(videoFrame.contentRect, CGRect(x: 0, y: 0, width: width, height: height))
            XCTAssertEqual(
                videoFrame.pixelBuffer.pixelFormat,
                kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
            )
            XCTAssertEqual(
                CVPixelBufferGetBytesPerRow(videoFrame.pixelBuffer),
                CVPixelBufferGetBytesPerRow(pixelBuffer)
            )
            XCTAssertEqual(
                CVPixelBufferGetPlaneCount(videoFrame.pixelBuffer),
                CVPixelBufferGetPlaneCount(pixelBuffer)
            )

            for plane in 0..<CVPixelBufferGetPlaneCount(videoFrame.pixelBuffer) {
                XCTAssertEqual(
                    CVPixelBufferGetBytesPerRowOfPlane(videoFrame.pixelBuffer, plane),
                    CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, plane)
                )
                XCTAssertEqual(
                    CVPixelBufferGetHeightOfPlane(videoFrame.pixelBuffer, plane),
                    CVPixelBufferGetHeightOfPlane(pixelBuffer, plane)
                )
            }
            handler.broadcastFinished()
            videoFrameExpectation.fulfill()
        }

        delegate.onStop = { error in
            XCTAssertNil(error)
            states.append(.stopped)
            stopExpectation.fulfill()
        }

        userDefaults.broadcastFps = 30
        handler.broadcastStarted()
        wait(for: [startExpectation, videoFrameExpectation, stopExpectation], timeout: 0.5)

        XCTAssertEqual(states, [.started, .newFrame, .stopped])
    }

    func testDeinit() {
        startReceiver()
        capturer = nil

        XCTAssertFalse(videoReceiver.isRunning)
        XCTAssertNil(userDefaults?.broadcastFps)
        XCTAssertNil(userDefaults?.broadcastKeepAliveDate)
    }

    // MARK: - Private

    private func startReceiver() {
        let expectation = self.expectation(description: "Sender started")
        notificationCenter.addObserver(self, for: .senderStarted) {
            expectation.fulfill()
        }
        notificationCenter.post(.senderStarted)
        wait(for: [expectation], timeout: 0.1)
    }
}

#endif
