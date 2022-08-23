import XCTest
@testable import PexipMedia

final class BandwidthTests: XCTestCase {
    func testInit() {
        XCTAssertEqual(Bandwidth(rawValue: 1024)?.rawValue, 1024)
        XCTAssertNil(Bandwidth(rawValue: 10_000))
    }

    func testLow() {
        XCTAssertEqual(Bandwidth.low, Bandwidth(rawValue: 512))
    }

    func testMedium() {
        XCTAssertEqual(Bandwidth.medium, Bandwidth(rawValue: 1264))
    }

    func testHigh() {
        XCTAssertEqual(Bandwidth.high, Bandwidth(rawValue: 2464))
    }

    func testVeryHigh() {
        XCTAssertEqual(Bandwidth.veryHigh, Bandwidth(rawValue: 6144))
    }
}
