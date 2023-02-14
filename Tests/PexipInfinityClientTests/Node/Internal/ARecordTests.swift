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
import dnssd
@testable import PexipInfinityClient

final class ARecordTests: XCTestCase {
    func testServiceType() {
        XCTAssertEqual(ARecord.serviceType, kDNSServiceType_A)
    }

    func testInit() throws {
        XCTAssertEqual(
            try ARecord(data: ARecord.Stub.default.data),
            ARecord.Stub.default.instance
        )
    }

    func testInitWithInvalidData() throws {
        for count in 1...3 {
            let bytes = [UInt8](repeating: 100, count: count)
            XCTAssertThrowsError(try ARecord(data: Data(bytes))) { error in
                XCTAssertEqual(error as? DNSLookupError, .invalidARecordData)
            }
        }

        XCTAssertThrowsError(
            try ARecord(data: "invalid data string".data(using: .utf8)!)
        ) { error in
            XCTAssertEqual(error as? DNSLookupError, .invalidARecordData)
        }
    }
}

// MARK: - Stubs

extension ARecord {
    struct Stub {
        let instance: ARecord
        let data: Data

        // Hostname:    px01.vc.example.com
        // IP address:  198.51.100.40
        static let `default` = Stub(
            instance: ARecord(ipv4Address: "198.51.100.40"),
            data: Data([198, 51, 100, 40])
        )
    }
}
