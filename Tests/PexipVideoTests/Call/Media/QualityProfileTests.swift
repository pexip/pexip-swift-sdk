import XCTest
@testable import PexipVideo

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

    func testVeryHigh() {
        let qualityProfile = QualityProfile.veryHigh

        XCTAssertEqual(qualityProfile.width, 1920)
        XCTAssertEqual(qualityProfile.height, 1080)
        XCTAssertEqual(qualityProfile.fps, 30)
        XCTAssertEqual(qualityProfile.bandwidth, 2880)
        XCTAssertEqual(qualityProfile.opusBitrate, 64)
    }

    func testHigh() {
        let qualityProfile = QualityProfile.high

        XCTAssertEqual(qualityProfile.width, 1280)
        XCTAssertEqual(qualityProfile.height, 720)
        XCTAssertEqual(qualityProfile.fps, 30)
        XCTAssertEqual(qualityProfile.bandwidth, 1280)
        XCTAssertEqual(qualityProfile.opusBitrate, 64)
    }

    func testMedium() {
        let qualityProfile = QualityProfile.medium

        XCTAssertEqual(qualityProfile.width, 720)
        XCTAssertEqual(qualityProfile.height, 480)
        XCTAssertEqual(qualityProfile.fps, 25)
        XCTAssertEqual(qualityProfile.bandwidth, 768)
        XCTAssertNil(qualityProfile.opusBitrate)
    }

    func testLow() {
        let qualityProfile = QualityProfile.low

        XCTAssertEqual(qualityProfile.width, 640)
        XCTAssertEqual(qualityProfile.height, 360)
        XCTAssertEqual(qualityProfile.fps, 15)
        XCTAssertEqual(qualityProfile.bandwidth, 384)
        XCTAssertNil(qualityProfile.opusBitrate)
    }
}
