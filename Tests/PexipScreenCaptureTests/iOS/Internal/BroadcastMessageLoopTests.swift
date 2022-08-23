#if os(iOS)

import XCTest
import CoreMedia
@testable import PexipScreenCapture

final class BroadcastMessageLoopTests: XCTestCase {
    private var delegate: BroadcastMessageLoopDelegateMock!
    private var messageLoop: BroadcastMessageLoop!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        delegate = BroadcastMessageLoopDelegateMock()
        messageLoop = BroadcastMessageLoop(fps: 15)
        messageLoop.delegate = delegate
    }

    override func tearDown() {
        messageLoop.stop()
        messageLoop = nil
        super.tearDown()
    }

    // MARK: - Tests

    func testInit() {
        XCTAssertEqual(messageLoop.fps, 15)
        XCTAssertFalse(messageLoop.isRunning)
    }

    func testStart() {
        XCTAssertTrue(messageLoop.start())
        XCTAssertTrue(messageLoop.isRunning)
    }

    func testStartWhenStarted() {
        XCTAssertTrue(messageLoop.start())
        XCTAssertTrue(messageLoop.isRunning)

        XCTAssertFalse(messageLoop.start())
        XCTAssertTrue(messageLoop.isRunning)
    }

    func testStop() {
        messageLoop.start()
        XCTAssertTrue(messageLoop.isRunning)

        messageLoop.stop()
        XCTAssertFalse(messageLoop.isRunning)
    }

    func testAddSampleBuffer() throws {
        let expectation = self.expectation(description: "Did prepare message")
        let width = 1920
        let height = 1080
        let pixelFormat = kCVPixelFormatType_32BGRA
        let orientation = CGImagePropertyOrientation.up
        let sampleBuffer = CMSampleBuffer.stub(
            width: width,
            height: height,
            pixelFormat: pixelFormat,
            orientation: orientation
        )
        let data = try XCTUnwrap(sampleBuffer.imageBuffer?.data)

        delegate.onMessage = { message in
            XCTAssertEqual(message.body, data)
            XCTAssertEqual(message.header.videoWidth, UInt32(width))
            XCTAssertEqual(message.header.videoHeight, UInt32(height))
            XCTAssertEqual(message.header.pixelFormat, pixelFormat)
            XCTAssertEqual(message.header.videoOrientation, orientation.rawValue)
            expectation.fulfill()
        }

        messageLoop.start()
        messageLoop.addSampleBuffer(sampleBuffer)

        wait(for: [expectation], timeout: 0.3)
    }

    func testFps() {
        let expectation = self.expectation(description: "Did prepare message")
        let maxTimeInterval = CMTime(fps: messageLoop.fps)
        var lastTime: CMTime?
        var iteration = 0

        delegate.onMessage = { _ in
            let currentTime = CMClockGetTime(CMClockGetHostTimeClock())

            if let lastTime = lastTime {
                let delta = CMTimeSubtract(currentTime, lastTime)

                XCTAssertEqual(
                    delta.seconds,
                    maxTimeInterval.seconds,
                    accuracy: 0.02
                )
            }

            iteration += 1
            lastTime = currentTime

            if iteration == 3 {
                expectation.fulfill()
            }
        }

        messageLoop.start()
        messageLoop.addSampleBuffer(.stub())

        wait(for: [expectation], timeout: 1)
    }
}

// MARK: - Mocks

private final class BroadcastMessageLoopDelegateMock: BroadcastMessageLoopDelegate {
    var onMessage: ((BroadcastMessage) -> Void)?

    func broadcastMessageLoop(
        _ messageLoop: BroadcastMessageLoop,
        didPrepareMessage message: BroadcastMessage
    ) {
        onMessage?(message)
    }
}

#endif
