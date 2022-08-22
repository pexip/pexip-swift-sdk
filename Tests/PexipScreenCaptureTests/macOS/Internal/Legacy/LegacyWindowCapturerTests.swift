#if os(macOS)

import XCTest
import CoreMedia
@testable import PexipScreenCapture

final class LegacyWindowCapturerTests: XCTestCase {
    private var window: WindowMock!
    private var capturer: LegacyWindowCapturer!
    private var delegate: ScreenMediaCapturerDelegateMock!
    private let fps: UInt = 15
    private let outputDimensions = CMVideoDimensions(width: 1280, height: 720)

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        window = WindowMock(
            windowID: 1,
            title: "Window 1",
            application: LegacyRunningApplication(
                processID: 1,
                bundleIdentifier: "com.pexip.Test",
                applicationName: "Test App"
            ),
            frame: CGRect(x: 0, y: 0, width: 1280, height: 720),
            isOnScreen: true,
            windowLayer: 0
        )

        delegate = ScreenMediaCapturerDelegateMock()

        capturer = LegacyWindowCapturer(window: window)
        capturer.delegate = delegate
    }

    override func tearDown() {
        window = nil
        capturer = nil
        super.tearDown()
    }

    // MARK: - Tests

    func testInit() {
        XCTAssertEqual(capturer.isCapturing, false)
        XCTAssertEqual(capturer.window.windowID, window.windowID)
    }

    func testStartCapture() async throws {
        let window = try XCTUnwrap(self.window)
        let expectation1 = self.expectation(description: "Frame complete 1")
        let expectation2 = self.expectation(description: "Frame complete 2")
        var timeNs = clock_gettime_nsec_np(CLOCK_UPTIME_RAW)

        capturer.displayTimeNs = { timeNs }

        try await capturer.startCapture(
            atFps: fps,
            outputDimensions: outputDimensions
        )

        XCTAssertTrue(capturer.isCapturing)

        var iteration = 0

        delegate.onVideoFrame = { [weak self] videoFrame in
            XCTAssertEqual(videoFrame.displayTimeNs, timeNs)
            XCTAssertEqual(videoFrame.width, UInt32(window.width))
            XCTAssertEqual(videoFrame.height, UInt32(window.height))
            XCTAssertEqual(videoFrame.orientation, .up)
            XCTAssertEqual(
                videoFrame.contentRect,
                CGRect(x: 0, y: 0, width: window.width, height: window.height)
            )

            iteration += 1

            if iteration == 1 {
                timeNs = clock_gettime_nsec_np(CLOCK_UPTIME_RAW)
                self?.capturer.displayTimeNs = { timeNs }
                expectation1.fulfill()
            } else if iteration == 2 {
                expectation2.fulfill()
            }
        }

        wait(for: [expectation1, expectation2], timeout: 1)
    }

    func testStopCapture() async throws {
        try await capturer.startCapture(
            atFps: fps,
            outputDimensions: outputDimensions
        )
        XCTAssertTrue(capturer.isCapturing)

        try capturer.stopCapture()
        XCTAssertFalse(capturer.isCapturing)
    }
}

// MARK: - Mocks

private struct WindowMock: Window {
    let windowID: CGWindowID
    let title: String?
    let application: RunningApplication?
    let frame: CGRect
    let isOnScreen: Bool
    let windowLayer: Int

    func createImage() -> CGImage? {
        CGImage.image(withColor: .red, width: width, height: height)
    }
}

#endif
