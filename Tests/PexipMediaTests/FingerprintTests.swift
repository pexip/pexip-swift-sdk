import XCTest
@testable import PexipMedia

final class FingerprintTests: XCTestCase {
    func testInit() {
        let type = "sha-256"
        let hash = "hash"
        let fingerprint = Fingerprint(type: type, hash: hash)

        XCTAssertEqual(fingerprint.type, type)
        XCTAssertEqual(fingerprint.hash, hash)
    }
}
