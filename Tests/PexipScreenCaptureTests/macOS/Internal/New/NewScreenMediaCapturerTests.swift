#if os(macOS)

import XCTest
@testable import PexipScreenCapture

#if canImport(ScreenCaptureKit)
import ScreenCaptureKit
#endif

@available(macOS 12.3, *)
// swiftlint:disable file_length
// swiftlint:disable type_body_length
final class NewScreenMediaCapturerTests: XCTestCase {
    private var capturer: NewScreenMediaCapturer<ScreenCaptureStreamFactoryMock>!
    private var display: LegacyDisplay!
    private var window: LegacyWindow!
    private var mediaSource: ScreenMediaSource!
    private var delegate: ScreenMediaCapturerDelegateMock!
    private var factory: ScreenCaptureStreamFactoryMock!
    private let fps: UInt = 15
    private let outputDimensions = CMVideoDimensions(width: 1280, height: 720)

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        display = LegacyDisplay.stub
        window = LegacyWindow.stub
        mediaSource = ScreenMediaSource.display(display)
        delegate = ScreenMediaCapturerDelegateMock()
        factory = ScreenCaptureStreamFactoryMock()
        capturer = NewScreenMediaCapturer(
            source: mediaSource,
            streamFactory: factory
        )
        capturer.delegate = delegate
    }

    override func tearDown() {
        ShareableContentMock.clear()
        super.tearDown()
    }

    // MARK: - Tests

    func testInitWithDisplayMediaSource() {
        capturer = NewScreenMediaCapturer(
            source: .display(display),
            streamFactory: factory
        )

        switch capturer.source {
        case .display(let value):
            XCTAssertEqual(value as? LegacyDisplay, display)
        case .window:
            XCTFail("Invalid video source")
        }
    }

    func testInitWithWindowMediaSource() throws {
        let window = try XCTUnwrap(window)
        capturer = NewScreenMediaCapturer(
            source: .window(window),
            streamFactory: factory
        )

        switch capturer.source {
        case .display:
            XCTFail("Invalid video source")
        case .window(let value):
            XCTAssertEqual(value.windowID, window.windowID)
        }
    }

    func testDeinit() throws {
        let expectation = self.expectation(description: "Deinit")
        ShareableContentMock.displays = [display]

        Task {
            try await capturer.startCapture(
                atFps: fps,
                outputDimensions: outputDimensions
            )
            let stream = try XCTUnwrap(factory.stream)

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

            capturer = nil
        }

        wait(for: [expectation], timeout: 0.3)
    }

    func testStartCaptureDisplay() async throws {
        ShareableContentMock.displays = [display]

        try await capturer.startCapture(
            atFps: fps,
            outputDimensions: outputDimensions
        )
        let stream = try XCTUnwrap(factory.stream)

        XCTAssertEqual(stream.configuration.backgroundColor, .black)
        XCTAssertEqual(
            stream.configuration.minimumFrameInterval,
            CMTime(fps: fps)
        )
        XCTAssertEqual(stream.configuration.width, display.width)
        XCTAssertEqual(stream.configuration.height, display.height)
        XCTAssertEqual(
            stream.configuration.pixelFormat,
            kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
        )

        XCTAssertNil(stream.delegate)
        XCTAssertTrue(stream.streamOutput === capturer)
        XCTAssertEqual(
            stream.sampleHandlerQueue?.label,
            "com.pexip.PexipScreenCapture.NewScreenMediaCapturer"
        )
        XCTAssertEqual(stream.sampleHandlerQueue?.qos, .userInteractive)

        XCTAssertEqual(
            stream.actions,
            [
                .addStreamOutput(.screen),
                .startCapture
            ]
        )

        XCTAssertTrue(capturer.isCapturing)
    }

    func testStartCaptureWindow() async throws {
        ShareableContentMock.windows = [window]

        capturer = NewScreenMediaCapturer(
            source: .window(window),
            streamFactory: factory
        )

        try await capturer.startCapture(
            atFps: fps,
            outputDimensions: outputDimensions
        )
        let stream = try XCTUnwrap(factory.stream)

        XCTAssertEqual(
            stream.configuration.minimumFrameInterval,
            CMTime(fps: fps)
        )
        XCTAssertEqual(stream.configuration.width, Int(outputDimensions.width))
        XCTAssertEqual(stream.configuration.height, Int(outputDimensions.height))

        XCTAssertNil(stream.delegate)
        XCTAssertTrue(stream.streamOutput === capturer)
        XCTAssertEqual(
            stream.sampleHandlerQueue?.label,
            "com.pexip.PexipScreenCapture.NewScreenMediaCapturer"
        )
        XCTAssertEqual(stream.sampleHandlerQueue?.qos, .userInteractive)

        XCTAssertEqual(
            stream.actions,
            [
                .addStreamOutput(.screen),
                .startCapture
            ]
        )

        XCTAssertTrue(capturer.isCapturing)
    }

    func testStopCapture() async throws {
        ShareableContentMock.displays = [display]

        try await capturer.startCapture(
            atFps: fps,
            outputDimensions: outputDimensions
        )
        let stream = try XCTUnwrap(factory.stream)

        XCTAssertTrue(capturer.isCapturing)

        try await capturer.stopCapture()

        XCTAssertEqual(
            stream.actions,
            [
                .addStreamOutput(.screen),
                .startCapture,
                .removeStreamOutput(.screen),
                .stopCapture
            ]
        )
        XCTAssertFalse(capturer.isCapturing)
    }

    func testSampleBufferWithoutAttachments() async throws {
        ShareableContentMock.displays = [display]

        try await capturer.startCapture(
            atFps: fps,
            outputDimensions: outputDimensions
        )

        let stream = try XCTUnwrap(factory.stream)
        let buffer = stream.createCMSampleBuffer(
            status: nil,
            displayTime: nil,
            contentRect: nil,
            scaleFactor: nil
        )

        capturer.stream(stream, didOutputSampleBuffer: buffer, of: .screen)

        XCTAssertTrue(capturer.isCapturing)
        XCTAssertNil(delegate.status)
    }

    func testSampleBufferWithoutStatus() async throws {
        ShareableContentMock.displays = [display]

        try await capturer.startCapture(
            atFps: fps,
            outputDimensions: outputDimensions
        )

        let stream = try XCTUnwrap(factory.stream)
        let time = mach_absolute_time()
        let buffer = stream.createCMSampleBuffer(
            status: nil,
            displayTime: time,
            contentRect: CGRect(x: 0, y: 0, width: 1280, height: 720),
            scaleFactor: 1
        )

        capturer.stream(stream, didOutputSampleBuffer: buffer, of: .screen)

        XCTAssertTrue(capturer.isCapturing)
        XCTAssertNil(delegate.status)
    }

    func testSampleBufferWithoutDisplayTime() async throws {
        ShareableContentMock.displays = [display]

        try await capturer.startCapture(
            atFps: fps,
            outputDimensions: outputDimensions
        )

        let stream = try XCTUnwrap(factory.stream)
        let buffer = stream.createCMSampleBuffer(
            status: .idle,
            displayTime: nil,
            contentRect: CGRect(x: 0, y: 0, width: 1280, height: 720),
            scaleFactor: 1
        )

        capturer.stream(stream, didOutputSampleBuffer: buffer, of: .screen)

        XCTAssertTrue(capturer.isCapturing)
        XCTAssertNil(delegate.status)
    }

    func testSampleBufferWithoutContentRect() async throws {
        ShareableContentMock.displays = [display]

        try await capturer.startCapture(
            atFps: fps,
            outputDimensions: outputDimensions
        )

        let stream = try XCTUnwrap(factory.stream)
        let buffer = stream.createCMSampleBuffer(
            status: .idle,
            displayTime: mach_absolute_time(),
            contentRect: nil,
            scaleFactor: 1
        )

        capturer.stream(stream, didOutputSampleBuffer: buffer, of: .screen)

        XCTAssertTrue(capturer.isCapturing)
        XCTAssertNil(delegate.status)
    }

    func testSampleBufferWithoutScaleFactor() async throws {
        ShareableContentMock.displays = [display]

        try await capturer.startCapture(
            atFps: fps,
            outputDimensions: outputDimensions
        )

        let stream = try XCTUnwrap(factory.stream)
        let buffer = stream.createCMSampleBuffer(
            status: .idle,
            displayTime: mach_absolute_time(),
            contentRect: CGRect(x: 0, y: 0, width: 1280, height: 720),
            scaleFactor: nil
        )

        capturer.stream(stream, didOutputSampleBuffer: buffer, of: .screen)

        XCTAssertTrue(capturer.isCapturing)
        XCTAssertNil(delegate.status)
    }

    func testSampleBufferWithStatusStopped() async throws {
        ShareableContentMock.displays = [display]

        try await capturer.startCapture(
            atFps: fps,
            outputDimensions: outputDimensions
        )

        let stream = try XCTUnwrap(factory.stream)
        let time = mach_absolute_time()
        let buffer = stream.createCMSampleBuffer(
            status: .stopped,
            displayTime: time,
            contentRect: CGRect(x: 0, y: 0, width: 1280, height: 720),
            scaleFactor: 1
        )

        capturer.stream(stream, didOutputSampleBuffer: buffer, of: .screen)

        XCTAssertFalse(capturer.isCapturing)

        switch delegate.status {
        case .complete, .none:
            XCTFail("Invalid video frame status")
        case .stopped(let error):
            XCTAssertNil(error)
        }
    }

    func testSampleBufferWithStatusComplete() async throws {
        ShareableContentMock.displays = [display]

        try await capturer.startCapture(
            atFps: fps,
            outputDimensions: outputDimensions
        )

        let stream = try XCTUnwrap(factory.stream)
        let time = mach_absolute_time()
        let buffer = stream.createCMSampleBuffer(
            status: .complete,
            displayTime: time,
            contentRect: CGRect(x: 0, y: 0, width: 500, height: 350),
            scaleFactor: 2
        )

        capturer.stream(stream, didOutputSampleBuffer: buffer, of: .screen)

        XCTAssertTrue(capturer.isCapturing)

        switch delegate.status {
        case .complete(let videoFrame):
            XCTAssertEqual(
                videoFrame.displayTimeNs,
                MachAbsoluteTime(time).nanoseconds
            )
            XCTAssertEqual(videoFrame.width, UInt32(outputDimensions.width))
            XCTAssertEqual(videoFrame.height, UInt32(outputDimensions.height))
            XCTAssertEqual(videoFrame.orientation, .up)
            XCTAssertEqual(
                videoFrame.contentRect,
                CGRect(x: 0, y: 0, width: 1000, height: 700)
            )
        case .stopped, .none:
            XCTFail("Invalid video frame status")
        }
    }

    func testSampleBufferWithOtherStatuses() async throws {
        ShareableContentMock.displays = [display]

        try await capturer.startCapture(
            atFps: fps,
            outputDimensions: outputDimensions
        )

        let stream = try XCTUnwrap(factory.stream)
        let statuses: [SCFrameStatus] = [
            .idle, .blank, .suspended, .started, .init(rawValue: 1000)!
        ]

        for status in statuses {
            let time = mach_absolute_time()
            let buffer = stream.createCMSampleBuffer(
                status: status,
                displayTime: time,
                contentRect: CGRect(x: 0, y: 0, width: 1280, height: 720),
                scaleFactor: 1
            )

            capturer.stream(stream, didOutputSampleBuffer: buffer, of: .screen)

            XCTAssertTrue(capturer.isCapturing)
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
    private(set) var mediaSource: ScreenMediaSource?

    func createStream(
        mediaSource: ScreenMediaSource,
        configuration: SCStreamConfiguration,
        delegate: SCStreamDelegate?
    ) async throws -> SCStream {
        self.mediaSource = mediaSource
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

    // swiftlint:disable function_body_length
    func createCMSampleBuffer(
        status: SCFrameStatus?,
        displayTime: UInt64?,
        contentRect: CGRect?,
        scaleFactor: CGFloat?
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

        let attachments: [Any?] = [status, displayTime, contentRect, scaleFactor]

        if !attachments.compactMap({ $0 }).isEmpty {
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

            if let contentRect = contentRect {
                CFDictionarySetValue(
                    dictionary,
                    Unmanaged.passUnretained(
                        SCStreamFrameInfo.contentRect.rawValue as CFString
                    ).toOpaque(),
                    Unmanaged.passRetained(
                        contentRect.dictionaryRepresentation
                    ).toOpaque()
                )
            }

            if let scaleFactor = scaleFactor {
                CFDictionarySetValue(
                    dictionary,
                    Unmanaged.passUnretained(
                        SCStreamFrameInfo.scaleFactor.rawValue as CFString
                    ).toOpaque(),
                    Unmanaged.passUnretained(scaleFactor as CFNumber).toOpaque()
                )
            }
        }

        return sampleBuffer!
    }
}

#endif
