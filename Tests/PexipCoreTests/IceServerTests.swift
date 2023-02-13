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
@testable import PexipCore

final class IceServerTests: XCTestCase {
    func testInitWithDefaults() {
        let urls = ["url1", "url2"]
        let iceServer = IceServer(kind: .stun, urls: urls)

        XCTAssertEqual(iceServer.kind, .stun)
        XCTAssertEqual(iceServer.urls, urls)
        XCTAssertNil(iceServer.username)
        XCTAssertNil(iceServer.password)
    }

    func testInitWithUrls() {
        let urls = ["url1", "url2"]
        let username = "User"
        let password = "Password"
        let iceServer = IceServer(
            kind: .turn,
            urls: urls,
            username: username,
            password: password
        )

        XCTAssertEqual(iceServer.kind, .turn)
        XCTAssertEqual(iceServer.urls, urls)
        XCTAssertEqual(iceServer.username, username)
        XCTAssertEqual(iceServer.password, password)
    }

    func testInitWithUrl() {
        let url = "url"
        let username = "User"
        let password = "Password"
        let iceServer = IceServer(
            kind: .stun,
            url: url,
            username: username,
            password: password
        )

        XCTAssertEqual(iceServer.kind, .stun)
        XCTAssertEqual(iceServer.urls, [url])
        XCTAssertEqual(iceServer.username, username)
        XCTAssertEqual(iceServer.password, password)
    }
}
