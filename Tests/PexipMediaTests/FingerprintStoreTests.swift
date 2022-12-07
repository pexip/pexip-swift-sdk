import XCTest
import Combine
import CryptoKit
@testable import PexipMedia

final class FingerprintStoreTests: XCTestCase {
    private var store: FingerprintStore!
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        store = FingerprintStore()
    }

    // MARK: - Tests

    func testSecureCheckCode() {
        let expectation = self.expectation(
            description: "Calculate secure check code"
        )
        let localFingerprints = [
            Fingerprint(type: "sha-256", hash: "hash3"),
            Fingerprint(type: "sha-256", hash: "hash1")
        ]
        let remoteFingerprints = [
            Fingerprint(type: "sha-256", hash: "hash4"),
            Fingerprint(type: "sha-256", hash: "hash2")
        ]
        var index = 0

        store.secureCheckCode.$value.sink { value in
            index += 1

            if index == 1 {
                XCTAssertEqual(value, SecureCheckCode.invalidValue)
            } else if index == 2 {
                let expectedString = "sha-256hash1sha-256hash3"
                let digest = SHA256.hash(data: Data(expectedString.utf8))
                XCTAssertEqual(value, digest.hashString)
            } else if index == 3 {
                let expectedString = "sha-256hash1sha-256hash2sha-256hash3sha-256hash4"
                let digest = SHA256.hash(data: Data(expectedString.utf8))
                XCTAssertEqual(value, digest.hashString)
                expectation.fulfill()
            }
        }.store(in: &cancellables)

        store.setLocalFingerprints(localFingerprints)
        store.setRemoteFingerprints(remoteFingerprints)

        wait(for: [expectation], timeout: 0.1)
    }
}
