//
// Copyright 2022-2023 Pexip AS
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

import Foundation
import Combine
import CryptoKit

public final class FingerprintStore {
    public let secureCheckCode = SecureCheckCode()

    private var localFingerprints = [Fingerprint]()
    private var remoteFingerprints = [Fingerprint]()

    public init() {}

    public func setLocalFingerprints(_ fingerprints: [Fingerprint]) {
        if localFingerprints != fingerprints {
            localFingerprints = fingerprints
            calculateSecureCheckCode()
        }
    }

    public func setRemoteFingerprints(_ fingerprints: [Fingerprint]) {
        if remoteFingerprints != fingerprints {
            remoteFingerprints = fingerprints
            calculateSecureCheckCode()
        }
    }

    public func reset() {
        localFingerprints.removeAll()
        remoteFingerprints.removeAll()
        secureCheckCode.value = SecureCheckCode.invalidValue
    }

    // MARK: - Private

    private func calculateSecureCheckCode() {
        let fingerprints = (localFingerprints + remoteFingerprints)
        let string = fingerprints.map(\.value).sorted().joined()
        let digest = SHA256.hash(data: Data(string.utf8))
        secureCheckCode.value = digest.hashString
    }
}

// MARK: - Internal extensions

extension SHA256.Digest {
    var hashString: String {
        compactMap({ String(format: "%02x", $0) }).joined()
    }
}
