import XCTest
@testable import PexipMedia

final class LocalMediaTrackTests: XCTestCase {
    func testCapturingStatus() {
        XCTAssertTrue(CapturingStatus(isCapturing: true).isCapturing)
        XCTAssertFalse(CapturingStatus(isCapturing: false).isCapturing)
    }
}
