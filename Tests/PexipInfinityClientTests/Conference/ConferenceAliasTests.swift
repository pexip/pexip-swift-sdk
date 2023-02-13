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

final class ConferenceAliasTests: XCTestCase {
    func testInitWithURI() throws {
        XCTAssertNil(ConferenceAlias(uri: ""))
        XCTAssertNil(ConferenceAlias(uri: "."))
        XCTAssertNil(ConferenceAlias(uri: "conference"))
        XCTAssertNil(ConferenceAlias(uri: "@example"))
        XCTAssertNil(ConferenceAlias(uri: "@example.com"))
        XCTAssertNil(ConferenceAlias(uri: "conference@example.com conference@example.com"))

        let name = try XCTUnwrap(ConferenceAlias(uri: "conference@example.com"))
        XCTAssertEqual(name.uri, "conference@example.com")
        XCTAssertEqual(name.alias, "conference")
        XCTAssertEqual(name.host, "example.com")
    }

    func testInitWithAliasAndHost() throws {
        XCTAssertNil(ConferenceAlias(alias: "", host: ""))
        XCTAssertNil(ConferenceAlias(alias: ".", host: "."))
        XCTAssertNil(ConferenceAlias(alias: "conference", host: "example"))
        XCTAssertNil(ConferenceAlias(alias: "@conference", host: "@example"))
        XCTAssertNil(ConferenceAlias(alias: "example.com", host: "conference"))
        XCTAssertNil(ConferenceAlias(alias: "conference", host: "example."))

        let name = try XCTUnwrap(ConferenceAlias(alias: "conference", host: "example.com"))
        XCTAssertEqual(name.uri, "conference@example.com")
        XCTAssertEqual(name.alias, "conference")
        XCTAssertEqual(name.host, "example.com")
    }
}
