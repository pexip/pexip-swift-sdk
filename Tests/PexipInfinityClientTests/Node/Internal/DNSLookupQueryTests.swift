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

final class DNSLookupQueryTests: XCTestCase {
    func testInit() throws {
        let query = DNSLookupQuery(
            domain: "example.org",
            serviceType: kDNSServiceType_A,
            handler: { _, _, _, _, _, _, _, _, _, _, _ in }
        )

        XCTAssertEqual(query.domain, "example.org")
        XCTAssertEqual(query.serviceType, kDNSServiceType_A)
    }
}
