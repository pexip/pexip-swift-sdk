//
// Copyright 2022 Pexip AS
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

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
