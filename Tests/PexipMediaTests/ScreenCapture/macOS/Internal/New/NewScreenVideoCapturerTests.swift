#if os(macOS)

import XCTest
@testable import PexipMedia

#if canImport(ScreenCaptureKit)
import ScreenCaptureKit
#endif

@available(macOS 12.3, *)
final class NewScreenVideoCapturerTests: XCTestCase {
    private var videoCapturer: NewScreenVideoCapturer<ScreenCaptureStreamFactoryMock>!
    private var display: LegacyDisplay!
    private var window: LegacyWindow!
    private var videoSource: ScreenVideoSource!
    private var delegate: ScreenVideoCapturerDelegateMock!
    private var factory: ScreenCaptureStreamFactoryMock!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        display = LegacyDisplay.stub
        window = LegacyWindow.stub
        videoSource = ScreenVideoSource.display(display)
        delegate = ScreenVideoCapturerDelegateMock()
        factory = ScreenCaptureStreamFactoryMock()
        videoCapturer = NewScreenVideoCapturer(
            videoSource: videoSource,
            streamFactory: factory
        )
        videoCapturer.delegate = delegate
    }

    override func tearDown() {
        ShareableContentMock.clear()
        super.tearDown()
    }

    // MARK: - Tests

    func testInitWithDisplayVideoSource() {
        videoCapturer = NewScreenVideoCapturer(
            videoSource: .display(display),
            streamFactory: factory
        )

        switch videoCapturer.videoSource {
        case .display(let value):
            XCTAssertEqual(value as? LegacyDisplay, display)
        case .window:
            XCTFail("Invalid video source")
        }
    }

    func testInitWithWindowVideoSource() throws {
        let window = try XCTUnwrap(window)
        videoCapturer = NewScreenVideoCapturer(
            videoSource: .window(window),
            streamFactory: factory
        )

        switch videoCapturer.videoSource {
        case .display:
            XCTFail("Invalid video source")
        case .window(let value):
            XCTAssertEqual(value.windowID, window.windowID)
        }
    }

    func testDeinit() async throws {
        let expectation = self.expectation(description: "Deinit")
        ShareableContentMock.displays = [display]

        try await videoCapturer.startCapture(withFps: 15)
        let stream = try XCTUnwrap(factory.stream)

        videoCapturer = nil

        stream.onStop = {
            XCTAssertEqual(
                stream.actions,
                [
                    .addStreamOutput(.screen),
                    .startCapture,
                    .removeStreamOutput(.screen),
                    .stopCapture
                ]
            )
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 0.1)
    }

    func testStartCaptureDisplay() async throws {
        let fps: UInt = 15
        ShareableContentMock.displays = [display]

        try await videoCapturer.startCapture(withFps: fps)
        let stream = try XCTUnwrap(factory.stream)

        XCTAssertEqual(
            stream.configuration.minimumFrameInterval,
            CMTime(fps: fps)
        )
        XCTAssertEqual(stream.configuration.width, display.width)
        XCTAssertEqual(stream.configuration.height, display.height)

        XCTAssertNil(stream.delegate)
        XCTAssertTrue(stream.streamOutput === videoCapturer)
        XCTAssertEqual(stream.sampleHandlerQueue?.label, "com.pexip.PexipMedia.NewScreenVideoCapturer")
        XCTAssertEqual(stream.sampleHandlerQueue?.qos, .userInteractive)

        XCTAssertEqual(
            stream.actions,
            [
                .addStreamOutput(.screen),
                .startCapture
            ]
        )

        XCTAssertTrue(videoCapturer.isCapturing)
    }

    func testStartCaptureWindow() async throws {
        let fps: UInt = 15
        ShareableContentMock.windows = [window]

        videoCapturer = NewScreenVideoCapturer(
            videoSource: .window(window),
            streamFactory: factory
        )

        try await videoCapturer.startCapture(withFps: fps)
        let stream = try XCTUnwrap(factory.stream)

        XCTAssertEqual(
            stream.configuration.minimumFrameInterval,
            CMTime(fps: fps)
        )
        XCTAssertEqual(stream.configuration.width, window.width)
        XCTAssertEqual(stream.configuration.height, window.height)

        XCTAssertNil(stream.delegate)
        XCTAssertTrue(stream.streamOutput === videoCapturer)
        XCTAssertEqual(stream.sampleHandlerQueue?.label, "com.pexip.PexipMedia.NewScreenVideoCapturer")
        XCTAssertEqual(stream.sampleHandlerQueue?.qos, .userInteractive)

        XCTAssertEqual(
            stream.actions,
            [
                .addStreamOutput(.screen),
                .startCapture
            ]
        )

        XCTAssertTrue(videoCapturer.isCapturing)
    }

    func testStopCapture() async throws {
        ShareableContentMock.displays = [display]

        try await videoCapturer.startCapture(withFps: 15)
        let stream = try XCTUnwrap(factory.stream)

        XCTAssertTrue(videoCapturer.isCapturing)

        try await videoCapturer.stopCapture()

        XCTAssertEqual(
            stream.actions,
            [
                .addStreamOutput(.screen),
                .startCapture,
                .removeStreamOutput(.screen),
                .stopCapture,
            ]
        )
        XCTAssertFalse(videoCapturer.isCapturing)
    }

    func testSampleBufferWithoutAttachments() async throws {
        ShareableContentMock.displays = [display]

        try await videoCapturer.startCapture(withFps: 15)

        let stream = try XCTUnwrap(factory.stream)
        let buffer = stream.createCMSampleBuffer(status: nil, displayTime: nil)

        videoCapturer.stream(stream, didOutputSampleBuffer: buffer, of: .screen)

        XCTAssertTrue(videoCapturer.isCapturing)
        XCTAssertNil(delegate.status)
    }

    func testSampleBufferWithoutStatus() async throws {
        ShareableContentMock.displays = [display]

        try await videoCapturer.startCapture(withFps: 15)

        let stream = try XCTUnwrap(factory.stream)
        let time = mach_absolute_time()
        let buffer = stream.createCMSampleBuffer(status: nil, displayTime: time)

        videoCapturer.stream(stream, didOutputSampleBuffer: buffer, of: .screen)

        XCTAssertTrue(videoCapturer.isCapturing)
        XCTAssertNil(delegate.status)
    }

    func testSampleBufferWithoutDisplayTime() async throws {
        ShareableContentMock.displays = [display]

        try await videoCapturer.startCapture(withFps: 15)

        let stream = try XCTUnwrap(factory.stream)
        let buffer = stream.createCMSampleBuffer(status: .idle, displayTime: nil)

        videoCapturer.stream(stream, didOutputSampleBuffer: buffer, of: .screen)

        XCTAssertTrue(videoCapturer.isCapturing)
        XCTAssertNil(delegate.status)
    }

    func testSampleBufferWithStatusStopped() async throws {
        ShareableContentMock.displays = [display]

        try await videoCapturer.startCapture(withFps: 15)

        let stream = try XCTUnwrap(factory.stream)
        let time = mach_absolute_time()
        let buffer = stream.createCMSampleBuffer(status: .stopped, displayTime: time)

        videoCapturer.stream(stream, didOutputSampleBuffer: buffer, of: .screen)

        XCTAssertFalse(videoCapturer.isCapturing)

        switch delegate.status {
        case .complete, .none:
            XCTFail("Invalid video frame status")
        case .stopped(let error):
            XCTAssertNil(error)
        }
    }

    func testSampleBufferWithStatusComplete() async throws {
        ShareableContentMock.displays = [display]

        try await videoCapturer.startCapture(withFps: 15)

        let stream = try XCTUnwrap(factory.stream)
        let time = mach_absolute_time()
        let buffer = stream.createCMSampleBuffer(status: .complete, displayTime: time)

        videoCapturer.stream(stream, didOutputSampleBuffer: buffer, of: .screen)

        XCTAssertTrue(videoCapturer.isCapturing)

        switch delegate.status {
        case .complete(let videoFrame):
            XCTAssertEqual(
                videoFrame.displayTimeNs,
                MachAbsoluteTime(time).nanoseconds
            )
            XCTAssertEqual(videoFrame.elapsedTimeNs, 0)
            XCTAssertEqual(videoFrame.width, UInt32(display.width))
            XCTAssertEqual(videoFrame.height, UInt32(display.height))
            XCTAssertEqual(videoFrame.orientation, .up)
        case .stopped, .none:
            XCTFail("Invalid video frame status")
        }
    }

    func testSampleBufferWithOtherStatuses() async throws {
        ShareableContentMock.displays = [display]

        try await videoCapturer.startCapture(withFps: 15)

        let stream = try XCTUnwrap(factory.stream)
        let statuses: [SCFrameStatus] = [
            .idle, .blank, .suspended, .started, .init(rawValue: 1000)!
        ]

        for status in statuses {
            let time = mach_absolute_time()
            let buffer = stream.createCMSampleBuffer(status: status, displayTime: time)

            videoCapturer.stream(stream, didOutputSampleBuffer: buffer, of: .screen)

            XCTAssertTrue(videoCapturer.isCapturing)
            XCTAssertNil(delegate.status)
        }
    }
}

// MARK: - Mocks

@available(macOS 12.3, *)
final class ScreenCaptureStreamFactoryMock: ScreenCaptureStreamFactory {
    typealias Content = ShareableContentMock
    typealias Filter = ScreenCaptureContentFilterMock

    private(set) var stream: StreamMock?
    private(set) var videoSource: ScreenVideoSource?

    func createStream(
        videoSource: ScreenVideoSource,
        configuration: SCStreamConfiguration,
        delegate: SCStreamDelegate?
    ) async throws -> SCStream {
        self.videoSource = videoSource
        stream = StreamMock(
            filter: SCContentFilter(),
            configuration: configuration,
            delegate: delegate
        )
        return stream!
    }
}

@available(macOS 12.3, *)
final class StreamMock: SCStream {
    enum Action: Hashable {
        case startCapture
        case stopCapture
        case addStreamOutput(SCStreamOutputType)
        case removeStreamOutput(SCStreamOutputType)
    }

    typealias Content = ShareableContentMock
    typealias Filter = ScreenCaptureContentFilterMock

    let configuration: SCStreamConfiguration
    var onStop: (() -> Void)?
    private(set) var actions = [Action]()
    private(set) weak var streamOutput: SCStreamOutput?
    private(set) weak var delegate: SCStreamDelegate?
    private(set) weak var sampleHandlerQueue: DispatchQueue?

    override init(
        filter contentFilter: SCContentFilter,
        configuration streamConfig: SCStreamConfiguration,
        delegate: SCStreamDelegate?
    ) {
        self.configuration = streamConfig
        self.delegate = delegate
        super.init(
            filter: contentFilter,
            configuration: configuration,
            delegate: nil
        )
    }

    override func addStreamOutput(
        _ output: SCStreamOutput,
        type: SCStreamOutputType,
        sampleHandlerQueue: DispatchQueue?
    ) throws {
        streamOutput = output
        self.sampleHandlerQueue = sampleHandlerQueue
        actions.append(.addStreamOutput(type))
    }

    override func removeStreamOutput(
        _ output: SCStreamOutput,
        type: SCStreamOutputType
    ) throws {
        actions.append(.removeStreamOutput(type))
    }

    override func startCapture() async throws {
        actions.append(.startCapture)
    }

    override func stopCapture() async throws {
        actions.append(.stopCapture)
        onStop?()
    }

    func createCMSampleBuffer(
        status: SCFrameStatus?,
        displayTime: UInt64?
    ) -> CMSampleBuffer {
        var pixelBuffer: CVPixelBuffer?

        CVPixelBufferCreate(
            kCFAllocatorDefault,
            configuration.width,
            configuration.height,
            configuration.pixelFormat,
            nil,
            &pixelBuffer
        )

        var info = CMSampleTimingInfo()
        info.presentationTimeStamp = CMTime.zero
        info.duration = CMTime.invalid
        info.decodeTimeStamp = CMTime.invalid

        var formatDesc: CMFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer!,
            formatDescriptionOut: &formatDesc
        )

        var sampleBuffer: CMSampleBuffer?

        CMSampleBufferCreateReadyWithImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer!,
            formatDescription: formatDesc!,
            sampleTiming: &info,
            sampleBufferOut: &sampleBuffer
        )

        if status != nil || displayTime != nil {
            let attachments: CFArray! = CMSampleBufferGetSampleAttachmentsArray(
                sampleBuffer!,
                createIfNecessary: true
            )

            let dictionary = unsafeBitCast(
                CFArrayGetValueAtIndex(attachments, 0),
                to: CFMutableDictionary.self
            )

            if let status = status {
                CFDictionarySetValue(
                    dictionary,
                    Unmanaged.passUnretained(
                        SCStreamFrameInfo.status.rawValue as CFString
                    ).toOpaque(),
                    Unmanaged.passUnretained(status.rawValue as CFNumber).toOpaque()
                )
            }

            if let displayTime = displayTime {
                CFDictionarySetValue(
                    dictionary,
                    Unmanaged.passUnretained(
                        SCStreamFrameInfo.displayTime.rawValue as CFString
                    ).toOpaque(),
                    Unmanaged.passUnretained(displayTime as CFNumber).toOpaque()
                )
            }
        }

        return sampleBuffer!
    }
}

#endif
