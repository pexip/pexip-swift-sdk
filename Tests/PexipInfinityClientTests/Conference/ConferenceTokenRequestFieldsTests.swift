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
@testable import PexipInfinityClient

final class ConferenceTokenRequestFieldsTests: XCTestCase {
    func testInit() {
        let identityProvider = IdentityProvider(name: "Name", id: UUID().uuidString)
        let ssoToken = UUID().uuidString
        let fields = ConferenceTokenRequestFields(
            displayName: "Name",
            conferenceExtension: "ext",
            idp: identityProvider,
            ssoToken: ssoToken,
            directMedia: false
        )

        XCTAssertEqual(fields.displayName, "Name")
        XCTAssertEqual(fields.conferenceExtension, "ext")
        XCTAssertEqual(fields.chosenIdpId, identityProvider.id)
        XCTAssertEqual(fields.ssoToken, ssoToken)
        XCTAssertFalse(fields.directMedia)
    }

    func testInitWithDefaults() {
        let fields = ConferenceTokenRequestFields(displayName: "Name")

        XCTAssertEqual(fields.displayName, "Name")
        XCTAssertNil(fields.conferenceExtension)
        XCTAssertNil(fields.chosenIdpId)
        XCTAssertNil(fields.ssoToken)
        XCTAssertFalse(fields.directMedia)
    }
}
