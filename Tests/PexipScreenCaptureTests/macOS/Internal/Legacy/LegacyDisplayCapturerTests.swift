import XCTest
import CoreMedia
@testable import PexipScreenCapture

#if os(macOS)

final class LegacyDisplayCapturerTests: XCTestCase {
    private var display: LegacyDisplay!
    private var capturer: LegacyDisplayCapturer!
    private var delegate: ScreenMediaCapturerDelegateMock!
    private let fps: UInt = 15
    private let outputDimensions = CMVideoDimensions(width: 1280, height: 720)
    private var displayStream: DisplayStreamMock? {
        DisplayStreamMock.current
    }

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        DisplayStreamMock.current = nil
        DisplayStreamMock.error = nil
        DisplayStreamMock.result = nil

        display = LegacyDisplay(displayID: 1, width: 1920, height: 1080)
        delegate = ScreenMediaCapturerDelegateMock()
        capturer = LegacyDisplayCapturer(
            display: display,
            displayStreamType: DisplayStreamMock.self
        )
        capturer.delegate = delegate
    }

    // MARK: - Tests

    func testInit() {
        XCTAssertFalse(capturer.isCapturing)
        XCTAssertEqual(capturer.display as? LegacyDisplay, display)
        XCTAssertTrue(capturer.displayStreamType is DisplayStreamMock.Type)
    }

    func testDeinit() async throws {
        try await capturer.startCapture(
            atFps: fps,
            outputDimensions: outputDimensions
        )

        let displayStream = try XCTUnwrap(displayStream)
        XCTAssertTrue(displayStream.isRunning)

        capturer = nil
        XCTAssertFalse(displayStream.isRunning)
    }

    func testStartCapture() async throws {
        try await capturer.startCapture(
            atFps: fps,
            outputDimensions: outputDimensions
        )
        let displayStream = try XCTUnwrap(displayStream)
        let properties: [CFString: Any] = [
            CGDisplayStream.preserveAspectRatio: kCFBooleanTrue as Any,
            CGDisplayStream.minimumFrameTime: CMTime(fps: fps).seconds as CFNumber
        ]

        XCTAssertTrue(capturer.isCapturing)
        XCTAssertTrue(displayStream.isRunning)

        XCTAssertEqual(displayStream.display, display.displayID)
        XCTAssertEqual(displayStream.outputWidth, Int(outputDimensions.width))
        XCTAssertEqual(displayStream.outputHeight, Int(outputDimensions.height))
        XCTAssertEqual(
            displayStream.pixelFormat,
            Int32(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)
        )
        XCTAssertEqual(displayStream.properties, properties as CFDictionary)
        XCTAssertEqual(
            displayStream.queue.label,
            "com.pexip.PexipMedia.LegacyDisplayCapturer"
        )
        XCTAssertEqual(displayStream.queue.qos, .userInteractive)
    }

    func testStartCaptureWithError() async throws {
        DisplayStreamMock.error = CGError.failure

        do {
            try await capturer.startCapture(atFps: fps, outputDimensions: outputDimensions)
            XCTFail("Should fail with error")
        } catch {
            XCTAssertNil(displayStream)
            XCTAssertEqual(error as? ScreenCaptureError, .cgError(.failure))
        }
    }

    func testDisplayStreamFrameStatusIdle() async throws {
        try await capturer.startCapture(
            atFps: fps,
            outputDimensions: outputDimensions
        )
        let displayStream = try XCTUnwrap(displayStream)
        displayStream.handler?(.frameBlank, mach_absolute_time(), nil, nil)

        XCTAssertTrue(capturer.isCapturing)
        XCTAssertNil(delegate.status)
    }

    func testDisplayStreamFrameStatusBlank() async throws {
        try await capturer.startCapture(
            atFps: fps,
            outputDimensions: outputDimensions
        )
        let displayStream = try XCTUnwrap(displayStream)
        displayStream.handler?(.frameBlank, mach_absolute_time(), nil, nil)

        XCTAssertTrue(capturer.isCapturing)
        XCTAssertNil(delegate.status)
    }

    func testDisplayStreamFrameStatusUnknown() async throws {
        try await capturer.startCapture(
            atFps: fps,
            outputDimensions: outputDimensions
        )
        let status = CGDisplayStreamFrameStatus(rawValue: 1001)!
        let displayStream = try XCTUnwrap(displayStream)
        displayStream.handler?(status, mach_absolute_time(), nil, nil)

        XCTAssertTrue(capturer.isCapturing)
        XCTAssertNil(delegate.status)
    }

    func testDisplayStreamFrameStatusStopped() async throws {
        try await capturer.startCapture(
            atFps: fps,
            outputDimensions: outputDimensions
        )
        let displayStream = try XCTUnwrap(displayStream)
        displayStream.handler?(.stopped, mach_absolute_time(), nil, nil)

        XCTAssertFalse(capturer.isCapturing)

        switch delegate.status {
        case .complete, .none:
            XCTFail("Invalid video frame status")
        case .stopped(let error):
            XCTAssertNil(error)
        }
    }

    func testDisplayStreamFrameStatusStoppedWhenNotCapturing() async throws {
        try await capturer.startCapture(
            atFps: fps,
            outputDimensions: outputDimensions
        )
        let displayStream = try XCTUnwrap(displayStream)
        let handler = displayStream.handler
        try capturer.stopCapture()

        handler?(.stopped, mach_absolute_time(), nil, nil)

        XCTAssertFalse(capturer.isCapturing)
        XCTAssertNil(delegate.status)
    }

    func testDisplayStreamFrameStatusComplete() async throws {
        try await capturer.startCapture(
            atFps: fps,
            outputDimensions: outputDimensions
        )
        let displayStream = try XCTUnwrap(displayStream)
        let ioSurface = displayStream.createIOSurface()
        let time = mach_absolute_time()
        displayStream.handler?(.frameComplete, time, ioSurface, nil)

        XCTAssertTrue(capturer.isCapturing)

        switch delegate.status {
        case .stopped, .none:
            XCTFail("Invalid video frame status")
        case .complete(let videoFrame):
            XCTAssertEqual(
                videoFrame.displayTimeNs,
                MachAbsoluteTime(time).nanoseconds
            )
            XCTAssertEqual(videoFrame.width, UInt32(displayStream.outputWidth))
            XCTAssertEqual(videoFrame.height, UInt32(displayStream.outputHeight))
            XCTAssertEqual(videoFrame.orientation, .up)
            XCTAssertEqual(
                videoFrame.contentRect,
                CGRect(
                    x: 0,
                    y: 0,
                    width: displayStream.outputWidth,
                    height: displayStream.outputHeight
                )
            )
        }
    }

    func testDisplayStreamFrameStatusCompleteWithNoIoSurface() async throws {
        try await capturer.startCapture(
            atFps: fps,
            outputDimensions: outputDimensions
        )
        let displayStream = try XCTUnwrap(displayStream)

        displayStream.handler?(.frameComplete, mach_absolute_time(), nil, nil)

        XCTAssertTrue(capturer.isCapturing)
        XCTAssertNil(delegate.status)
    }

    func testStopCapture() async throws {
        try await capturer.startCapture(
            atFps: fps,
            outputDimensions: outputDimensions
        )
        let displayStream = try XCTUnwrap(displayStream)

        XCTAssertTrue(capturer.isCapturing)
        XCTAssertTrue(displayStream.isRunning)

        try capturer.stopCapture()

        XCTAssertFalse(capturer.isCapturing)
        XCTAssertFalse(displayStream.isRunning)
    }

    func testStopCaptureWithError() async throws {
        try await capturer.startCapture(
            atFps: fps,
            outputDimensions: outputDimensions
        )
        let displayStream = try XCTUnwrap(displayStream)

        XCTAssertTrue(capturer.isCapturing)
        XCTAssertTrue(displayStream.isRunning)

        do {
            DisplayStreamMock.error = CGError.failure
            try capturer.stopCapture()
        } catch {
            XCTAssertFalse(capturer.isCapturing)
            XCTAssertFalse(displayStream.isRunning)
            XCTAssertEqual(error as? ScreenCaptureError, .cgError(.failure))
        }
    }
}

// MARK: - Mocks

private final class DisplayStreamMock: LegacyDisplayStream {
    struct HandlerResult {
        let status: CGDisplayStreamFrameStatus
        let displayTime: UInt64
        let ioSurface: IOSurfaceRef?
    }

    static weak var current: DisplayStreamMock?
    static var result: HandlerResult?
    static var error: CGError?

    private(set) var isRunning = false
    let display: CGDirectDisplayID
    let outputWidth: Int
    let outputHeight: Int
    let pixelFormat: Int32
    let properties: CFDictionary?
    let queue: DispatchQueue
    let handler: CGDisplayStreamFrameAvailableHandler?

    init?(
        dispatchQueueDisplay display: CGDirectDisplayID,
        outputWidth: Int,
        outputHeight: Int,
        pixelFormat: Int32,
        properties: CFDictionary?,
        queue: DispatchQueue,
        handler: CGDisplayStreamFrameAvailableHandler?
    ) {
        self.display = display
        self.outputWidth = outputWidth
        self.outputHeight = outputHeight
        self.pixelFormat = pixelFormat
        self.properties = properties
        self.queue = queue
        self.handler = handler
        Self.current = self
    }

    func start() -> CGError {
        if let result = Self.result {
            handler?(result.status, result.displayTime, result.ioSurface, nil)
        }
        isRunning = true
        return Self.error ?? .success
    }

    func stop() -> CGError {
        isRunning = false
        return Self.error ?? .success
    }

    func createIOSurface() -> IOSurfaceRef? {
        .stub(width: outputWidth, height: outputHeight, pixelFormat: pixelFormat)
    }
}

private extension IOSurfaceRef {
    static func stub(width: Int, height: Int, pixelFormat: Int32) -> IOSurfaceRef? {
        IOSurfaceCreate([
            kIOSurfaceWidth: width,
            kIOSurfaceHeight: height,
            kIOSurfaceBytesPerElement: 4,
            kIOSurfaceBytesPerRow: width * 4,
            kIOSurfaceAllocSize: width * height * 4,
            kIOSurfacePixelFormat: pixelFormat
        ] as CFDictionary)
    }
}

#endif

final class ScreenMediaCapturerDelegateMock: ScreenMediaCapturerDelegate {
    var onVideoFrame: ((VideoFrame) -> Void)?
    var onStop: ((Error?) -> Void)?
    private(set) var status: VideoFrame.Status?

    func screenMediaCapturer(
        _ capturer: ScreenMediaCapturer,
        didCaptureVideoFrame frame: VideoFrame
    ) {
        status = .complete(frame)
        onVideoFrame?(frame)
    }

    func screenMediaCapturer(
        _ capturer: ScreenMediaCapturer,
        didStopWithError error: Error?
    ) {
        status = .stopped(error: error)
        onStop?(error)
    }
}
