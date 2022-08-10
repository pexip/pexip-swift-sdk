import XCTest
import Vision
import CoreMedia
@testable import PexipVideoFilters

@available(iOS 15.0, *)
@available(macOS 12.0, *)
final class VideoFilterTests: XCTestCase {
    private var factory: VideoFilterFactory!
    private var pixelBuffer: CVPixelBuffer!
    private let machToSeconds: Double = {
        var timebase: mach_timebase_info_data_t = mach_timebase_info_data_t()
        mach_timebase_info(&timebase)
        return Double(timebase.numer) / Double(timebase.denom) * 1e-9
    }()

    override class var defaultMetrics: [XCTMetric] {[
        XCTClockMetric(),
        XCTCPUMetric(),
        XCTMemoryMetric()
    ]}

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        factory = VideoFilterFactory()
        pixelBuffer = CMSampleBuffer.stub(width: 1920, height: 1080).imageBuffer
    }

    // MARK: - Tests

    func testGaussianBlur() {
        let filter = factory.gaussianBlur()
        var resultPixelBuffer: CVPixelBuffer?

        // Run 1
        #if os(macOS)
        measure(metrics: Self.defaultMetrics) {
            resultPixelBuffer = filter.processPixelBuffer(pixelBuffer, orientation: .up)
        }
        #endif

        // Run 2
        let startTime = mach_absolute_time()
        resultPixelBuffer = filter.processPixelBuffer(pixelBuffer, orientation: .up)
        let endTime = mach_absolute_time()
        let seconds = machToSeconds * Double(endTime - startTime)

        XCTAssertTrue(seconds <= 0.05)
        XCTAssertEqual(resultPixelBuffer?.width, 1920)
        XCTAssertEqual(resultPixelBuffer?.height, 1080)
        XCTAssertEqual(resultPixelBuffer?.pixelFormat, pixelBuffer.pixelFormat)
    }

    func testTentBlur() {
        let filter = factory.tentBlur()
        var resultPixelBuffer: CVPixelBuffer?

        // Run 1
        #if os(macOS)
        measure(metrics: Self.defaultMetrics) {
            resultPixelBuffer = filter.processPixelBuffer(pixelBuffer, orientation: .up)
        }
        #endif

        // Run 2
        let startTime = mach_absolute_time()
        resultPixelBuffer = filter.processPixelBuffer(pixelBuffer, orientation: .up)
        let endTime = mach_absolute_time()
        let seconds = machToSeconds * Double(endTime - startTime)

        XCTAssertTrue(seconds <= 0.046)
        XCTAssertEqual(resultPixelBuffer?.width, 1920)
        XCTAssertEqual(resultPixelBuffer?.height, 1080)
        XCTAssertEqual(resultPixelBuffer?.pixelFormat, pixelBuffer.pixelFormat)
    }

    func testBoxBlur() {
        let filter = factory.boxBlur()
        var resultPixelBuffer: CVPixelBuffer?

        // Run 1
        #if os(macOS)
        measure(metrics: Self.defaultMetrics) {
            resultPixelBuffer = filter.processPixelBuffer(pixelBuffer, orientation: .up)
        }
        #endif

        // Run 2
        let startTime = mach_absolute_time()
        resultPixelBuffer = filter.processPixelBuffer(pixelBuffer, orientation: .up)
        let endTime = mach_absolute_time()
        let seconds = machToSeconds * Double(endTime - startTime)

        XCTAssertTrue(seconds <= 0.07)
        XCTAssertEqual(resultPixelBuffer?.width, 1920)
        XCTAssertEqual(resultPixelBuffer?.height, 1080)
        XCTAssertEqual(resultPixelBuffer?.pixelFormat, pixelBuffer.pixelFormat)
    }

    func testVirtualBackgroundImage() throws {
        let image = try XCTUnwrap(CGImage.image(width: 1920, height: 1080))
        let filter = factory.virtualBackground(image: image)
        var resultPixelBuffer: CVPixelBuffer?

        // Run 1
        #if os(macOS)
        measure(metrics: Self.defaultMetrics) {
            resultPixelBuffer = filter.processPixelBuffer(pixelBuffer, orientation: .up)
        }
        #endif

        // Run 2
        let startTime = mach_absolute_time()
        resultPixelBuffer = filter.processPixelBuffer(pixelBuffer, orientation: .up)
        let endTime = mach_absolute_time()
        let seconds = machToSeconds * Double(endTime - startTime)

        XCTAssertTrue(seconds <= 0.04)
        XCTAssertEqual(resultPixelBuffer?.width, 1920)
        XCTAssertEqual(resultPixelBuffer?.height, 1080)
        XCTAssertEqual(resultPixelBuffer?.pixelFormat, pixelBuffer.pixelFormat)
    }

    func testVirtualBackgroundVideo() throws {
        let url = try XCTUnwrap(
            Bundle.module.url(forResource: "testVideo", withExtension: "mp4")
        )
        let filter = factory.virtualBackground(videoURL: url)
        var resultPixelBuffer: CVPixelBuffer?

        // Run 1
        #if os(macOS)
        measure(metrics: Self.defaultMetrics) {
            resultPixelBuffer = filter.processPixelBuffer(pixelBuffer, orientation: .up)
        }
        #endif

        // Run 2
        let startTime = mach_absolute_time()
        resultPixelBuffer = filter.processPixelBuffer(pixelBuffer, orientation: .up)
        let endTime = mach_absolute_time()
        let seconds = machToSeconds * Double(endTime - startTime)

        XCTAssertTrue(seconds <= 0.05)
        XCTAssertEqual(resultPixelBuffer?.width, 1920)
        XCTAssertEqual(resultPixelBuffer?.height, 1080)
        XCTAssertEqual(resultPixelBuffer?.pixelFormat, pixelBuffer.pixelFormat)
    }
}

// MARK: - Private extensions

private extension CVPixelBuffer {
    var pixelFormat: UInt32 {
        CVPixelBufferGetPixelFormatType(self)
    }

    var width: UInt32 {
        UInt32(CVPixelBufferGetWidth(self))
    }

    var height: UInt32 {
        UInt32(CVPixelBufferGetHeight(self))
    }
}
