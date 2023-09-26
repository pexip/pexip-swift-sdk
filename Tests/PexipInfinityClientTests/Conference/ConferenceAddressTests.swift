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

import XCTest
import dnssd
@testable import PexipInfinityClient

final class ConferenceAddressTests: XCTestCase {
    func testInitWithURI() throws {
        XCTAssertNil(ConferenceAddress(uri: ""))
        XCTAssertNil(ConferenceAddress(uri: "."))
        XCTAssertNil(ConferenceAddress(uri: "conference"))
        XCTAssertNil(ConferenceAddress(uri: "@example"))
        XCTAssertNil(ConferenceAddress(uri: "@example.com"))
        XCTAssertNil(ConferenceAddress(uri: "conference@example.com conference@example.com"))

        let name = try XCTUnwrap(ConferenceAddress(uri: "conference@example.com"))
        XCTAssertEqual(name.alias, "conference@example.com")
        XCTAssertEqual(name.host, "example.com")
    }

    func testInitWithAliasAndHost() throws {
        let name = ConferenceAddress(alias: "conference", host: "example.com")
        XCTAssertEqual(name.alias, "conference")
        XCTAssertEqual(name.host, "example.com")
    }
}
