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
@testable import PexipInfinityClient

final class ConferenceTokenErrorTests: XCTestCase {
    private let decoder = JSONDecoder()

    // MARK: - Tests

    func testDecodingPinRequiredWithRequiredPin() throws {
        let data = """
        {
            "pin": "required",
            "guest_pin": "required"
        }
        """.data(using: .utf8)

        let error = try decoder.decode(
            ConferenceTokenError.self,
            from: try XCTUnwrap(data)
        )

        XCTAssertEqual(error, .pinRequired(guestPin: true))
    }

    func testDecodingPinRequiredWithOptionalPin() throws {
        let data = """
        {
            "pin": "required",
            "guest_pin": "none"
        }
        """.data(using: .utf8)

        let error = try decoder.decode(
            ConferenceTokenError.self,
            from: try XCTUnwrap(data)
        )

        XCTAssertEqual(error, .pinRequired(guestPin: false))
    }

    func testDecodingConferenceExtensionRequired() throws {
        let data = """
        {
            "conference_extension": "standard"
        }
        """.data(using: .utf8)

        let error = try decoder.decode(
            ConferenceTokenError.self,
            from: try XCTUnwrap(data)
        )

        XCTAssertEqual(error, .conferenceExtensionRequired("standard"))
    }

    func testDecodingSSOIdentityProviderRequired() throws {
        let uuid1 = UUID().uuidString.lowercased()
        let uuid2 = UUID().uuidString.lowercased()
        let data = """
        {
            "idp": [
                {
                    "name": "IDP1",
                    "uuid": "\(uuid1)"
                },
                {
                    "name": "IDP2",
                    "uuid": "\(uuid2)"
                }
            ]
        }
        """.data(using: .utf8)

        let error = try decoder.decode(
            ConferenceTokenError.self,
            from: try XCTUnwrap(data)
        )

        XCTAssertEqual(
            error,
            .ssoIdentityProviderRequired([
                .init(name: "IDP1", id: uuid1),
                .init(name: "IDP2", id: uuid2)
            ])
        )
    }

    func testDecodingSSOIdentityProviderRedirect() throws {
        let uuid = UUID().uuidString.lowercased()
        let data = """
        {
            "redirect_url": "https://example.com?idp=test",
            "redirect_idp": {
                "name": "IDP1",
                "uuid": "\(uuid)"
            }
        }
        """.data(using: .utf8)

        let error = try decoder.decode(
            ConferenceTokenError.self,
            from: try XCTUnwrap(data)
        )

        XCTAssertEqual(
            error,
            .ssoIdentityProviderRedirect(
                idp: .init(name: "IDP1", id: uuid),
                url: try XCTUnwrap(URL(string: "https://example.com?idp=test"))
            )
        )
    }

    func testDecodingFailed() throws {
        let data = """
        {
            "field": "value"
        }
        """.data(using: .utf8)

        let error = try decoder.decode(
            ConferenceTokenError.self,
            from: try XCTUnwrap(data)
        )

        XCTAssertEqual(error, .tokenDecodingFailed)
    }
}
