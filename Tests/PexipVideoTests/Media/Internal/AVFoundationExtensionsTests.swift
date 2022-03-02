import XCTest
import AVFoundation
@testable import PexipVideo

final class AVFoundationExtensionsTests: XCTestCase {
    private var formats: [FormatMock]!

    // MARK: - Setup

    override func setUpWithError() throws {
        try super.setUpWithError()
        formats = [
            try formatDescription(width: 192, height: 144),
            try formatDescription(width: 352, height: 288),
            try formatDescription(width: 480, height: 360),
            try formatDescription(width: 640, height: 480),
            try formatDescription(width: 960, height: 540),
            try formatDescription(width: 1024, height: 768),
            try formatDescription(width: 1280, height: 720),
            try formatDescription(width: 1440, height: 1080),
            try formatDescription(width: 1920, height: 1080),
            try formatDescription(width: 1920, height: 1440),
            try formatDescription(width: 3088, height: 2316),
            try formatDescription(width: 3040, height: 2160),
            try formatDescription(width: 4032, height: 3024)
        ]
    }

    // MARK: - Tests

    func testBestFormatLow() throws {
        let formatDescription = try XCTUnwrap(
            formats.bestFormat(for: .low)?.formatDescription
        )
        let dimensions = CMVideoFormatDescriptionGetDimensions(formatDescription)

        XCTAssertEqual(dimensions.width, 480)
        XCTAssertEqual(dimensions.height, 360)
    }

    func testBestFormatMedium() throws {
        let formatDescription = try XCTUnwrap(
            formats.bestFormat(for: .medium)?.formatDescription
        )
        let dimensions = CMVideoFormatDescriptionGetDimensions(formatDescription)

        XCTAssertEqual(dimensions.width, 960)
        XCTAssertEqual(dimensions.height, 540)
    }

    func testBestFormatHigh() throws {
        let formatDescription = try XCTUnwrap(
            formats.bestFormat(for: .high)?.formatDescription
        )
        let dimensions = CMVideoFormatDescriptionGetDimensions(formatDescription)

        XCTAssertEqual(dimensions.width, 1280)
        XCTAssertEqual(dimensions.height, 720)
    }

    func testBestFormatVeryHigh() throws {
        let formatDescription = try XCTUnwrap(
            formats.bestFormat(for: .veryHigh)?.formatDescription
        )
        let dimensions = CMVideoFormatDescriptionGetDimensions(formatDescription)

        XCTAssertEqual(dimensions.width, 1920)
        XCTAssertEqual(dimensions.height, 1080)
    }

    func testBestFrameRate() {
        let frameRanges = [
            FrameRateRangeMock(maxFrameRate: 30),
            FrameRateRangeMock(maxFrameRate: 60),
            FrameRateRangeMock(maxFrameRate: 120)
        ]

        XCTAssertEqual([FrameRateRangeMock]().bestFrameRate(for: .low), 15)
        XCTAssertEqual(frameRanges.bestFrameRate(for: .low), 15)
        XCTAssertEqual(frameRanges.bestFrameRate(for: .medium), 25)
        XCTAssertEqual(frameRanges.bestFrameRate(for: .high), 30)
        XCTAssertEqual(frameRanges.bestFrameRate(for: .veryHigh), 30)
    }

    /// No capture devices on Simulator
    func testVideoCaptureDevices() {
        XCTAssertTrue(AVCaptureDevice.videoCaptureDevices(withPosition: .front).isEmpty)
        XCTAssertTrue(AVCaptureDevice.videoCaptureDevices(withPosition: .back).isEmpty)
        XCTAssertTrue(AVCaptureDevice.videoCaptureDevices(withPosition: .unspecified).isEmpty)
    }

    // MARK: - Helpers

    private func formatDescription(
        width: Int32,
        height: Int32
    ) throws -> FormatMock {
        var formatDescription: CMFormatDescription?

        CMVideoFormatDescriptionCreate(
            allocator: kCFAllocatorDefault,
            codecType: kCMVideoCodecType_422YpCbCr8,
            width: Int32(width),
            height: Int32(height),
            extensions: nil,
            formatDescriptionOut: &formatDescription
        )

        return FormatMock(
            formatDescription: try XCTUnwrap(formatDescription)
        )
    }
}

// MARK: - Mocks

private struct FormatMock: CaptureDeviceFormat {
    let formatDescription: CMFormatDescription
}

private struct FrameRateRangeMock: FrameRateRange {
    let maxFrameRate: Float64
}
