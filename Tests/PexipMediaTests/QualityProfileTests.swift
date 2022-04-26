import XCTest
import CoreMedia
@testable import PexipMedia

final class QualityProfileTests: XCTestCase {
    func testInit() {
        let qualityProfile = QualityProfile(
            width: 1920,
            height: 1080,
            fps: 60,
            bandwidth: 2880,
            opusBitrate: 64
        )

        XCTAssertEqual(qualityProfile.width, 1920)
        XCTAssertEqual(qualityProfile.height, 1080)
        XCTAssertEqual(qualityProfile.fps, 60)
        XCTAssertEqual(qualityProfile.bandwidth, 2880)
        XCTAssertEqual(qualityProfile.opusBitrate, 64)
    }

    func testDefault() {
        XCTAssertEqual(QualityProfile.default, .high)
    }

    func testHigh() {
        let qualityProfile = QualityProfile.high

        XCTAssertEqual(qualityProfile.width, 1280)
        XCTAssertEqual(qualityProfile.height, 720)
        XCTAssertEqual(qualityProfile.fps, 30)
        XCTAssertEqual(qualityProfile.bandwidth, 1280)
        XCTAssertEqual(qualityProfile.opusBitrate, 64)
    }

    #if os(iOS)

    func testVeryHigh() {
        let qualityProfile = QualityProfile.veryHigh

        XCTAssertEqual(qualityProfile.width, 1920)
        XCTAssertEqual(qualityProfile.height, 1080)
        XCTAssertEqual(qualityProfile.fps, 30)
        XCTAssertEqual(qualityProfile.bandwidth, 2880)
        XCTAssertEqual(qualityProfile.opusBitrate, 64)
    }

    func testMedium() {
        let qualityProfile = QualityProfile.medium

        XCTAssertEqual(qualityProfile.width, 960)
        XCTAssertEqual(qualityProfile.height, 540)
        XCTAssertEqual(qualityProfile.fps, 25)
        XCTAssertEqual(qualityProfile.bandwidth, 768)
        XCTAssertNil(qualityProfile.opusBitrate)
    }

    func testLow() {
        let qualityProfile = QualityProfile.low

        XCTAssertEqual(qualityProfile.width, 480)
        XCTAssertEqual(qualityProfile.height, 360)
        XCTAssertEqual(qualityProfile.fps, 15)
        XCTAssertEqual(qualityProfile.bandwidth, 384)
        XCTAssertNil(qualityProfile.opusBitrate)
    }

    #else

    func testMedium() {
        let qualityProfile = QualityProfile.medium

        XCTAssertEqual(qualityProfile.width, 640)
        XCTAssertEqual(qualityProfile.height, 480)
        XCTAssertEqual(qualityProfile.fps, 30)
        XCTAssertEqual(qualityProfile.bandwidth, 768)
    }

    #endif

    // MARK: - Best format

    func testBestFormatHigh() throws {
        let dimensions = try bestFormatDimensions(for: .high)
        XCTAssertEqual(dimensions.width, 1280)
        XCTAssertEqual(dimensions.height, 720)
    }

    #if os(iOS)

    func testBestFormatVeryHigh() throws {
        let dimensions = try bestFormatDimensions(for: .veryHigh)
        XCTAssertEqual(dimensions.width, 1920)
        XCTAssertEqual(dimensions.height, 1080)
    }

    func testBestFormatMedium() throws {
        let dimensions = try bestFormatDimensions(for: .medium)
        XCTAssertEqual(dimensions.width, 960)
        XCTAssertEqual(dimensions.height, 540)
    }

    func testBestFormatLow() throws {
        let dimensions = try bestFormatDimensions(for: .low)
        XCTAssertEqual(dimensions.width, 480)
        XCTAssertEqual(dimensions.height, 360)
    }

    #else

    func testBestFormatMedium() throws {
        let dimensions = try bestFormatDimensions(for: .medium)
        XCTAssertEqual(dimensions.width, 640)
        XCTAssertEqual(dimensions.height, 480)
    }

    #endif

    func testBestFrameRate() {
        XCTAssertNil(
            QualityProfile.default.bestFrameRate(
                from: [FrameRateRange](),
                maxFrameRate: \.maxFrameRate
            )
        )

        XCTAssertEqual(bestFrameRange(for: .high), 30)

        #if os(iOS)
        XCTAssertEqual(bestFrameRange(for: .low), 15)
        XCTAssertEqual(bestFrameRange(for: .medium), 25)
        XCTAssertEqual(bestFrameRange(for: .veryHigh), 30)
        #else
        XCTAssertEqual(bestFrameRange(for: .medium), 30)
        #endif
    }

    // MARK: - Helpers

    private func bestFormatDimensions(
        for qualityProfile: QualityProfile
    ) throws -> CMVideoDimensions {
        let format = qualityProfile.bestFormat(
            from: try Format.testFormats(),
            formatDescription: \.formatDescription
        )
        let formatDescription = try XCTUnwrap(format?.formatDescription)
        return CMVideoFormatDescriptionGetDimensions(formatDescription)
    }

    private func bestFrameRange(for qualityProfile: QualityProfile) -> Float64? {
        qualityProfile.bestFrameRate(
            from: FrameRateRange.testFrameRanges,
            maxFrameRate: \.maxFrameRate
        )
    }
}

// MARK: - Mocks

private struct Format {
    let formatDescription: CMFormatDescription

    static func testFormats() throws -> [Format] {
        [
            try format(width: 192, height: 144),
            try format(width: 352, height: 288),
            try format(width: 480, height: 360),
            try format(width: 640, height: 480),
            try format(width: 960, height: 540),
            try format(width: 1024, height: 768),
            try format(width: 1280, height: 720),
            try format(width: 1440, height: 1080),
            try format(width: 1920, height: 1080),
            try format(width: 1920, height: 1440),
            try format(width: 3088, height: 2316),
            try format(width: 3040, height: 2160),
            try format(width: 4032, height: 3024)
        ]
    }

    private static func format(
        width: Int32,
        height: Int32
    ) throws -> Format {
        var formatDescription: CMFormatDescription?

        CMVideoFormatDescriptionCreate(
            allocator: kCFAllocatorDefault,
            codecType: kCMVideoCodecType_422YpCbCr8,
            width: Int32(width),
            height: Int32(height),
            extensions: nil,
            formatDescriptionOut: &formatDescription
        )

        return Format(
            formatDescription: try XCTUnwrap(formatDescription)
        )
    }
}

private struct FrameRateRange {
    static let testFrameRanges = [
        FrameRateRange(maxFrameRate: 30),
        FrameRateRange(maxFrameRate: 60),
        FrameRateRange(maxFrameRate: 120)
    ]

    let maxFrameRate: Float64
}
