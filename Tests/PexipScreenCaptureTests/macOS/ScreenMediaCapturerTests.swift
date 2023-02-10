#if os(macOS)

import XCTest
import CoreMedia
@testable import PexipScreenCapture

final class ScreenMediaCapturerTests: XCTestCase {
    func testStopCaptureWithReason() async throws {
        let capturer = ScreenMediaCapturerMock()
        try await capturer.stopCapture(reason: .presentationStolen)
        XCTAssertTrue(capturer.stopCalled)
    }
}

// MARK: - Mocks

private final class ScreenMediaCapturerMock: ScreenMediaCapturer {
    var delegate: PexipScreenCapture.ScreenMediaCapturerDelegate?

    func startCapture(
        atFps fps: UInt,
        outputDimensions: CMVideoDimensions
    ) async throws {}

    private(set) var stopCalled = false

    func stopCapture() async throws {
        stopCalled = true
    }
}

#endif
