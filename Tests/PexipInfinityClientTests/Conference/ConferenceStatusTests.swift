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

final class ConferenceStatusTests: XCTestCase {
    func testStatusDecoding() throws {
        let status = ConferenceStatus(
            started: true,
            locked: false,
            allMuted: false,
            guestsMuted: false,
            presentationAllowed: true,
            directMedia: false,
            liveCaptionsAvailable: true
        )
        let json = """
        {
            "started": \(status.started),
            "locked": \(status.locked),
            "all_muted": \(status.allMuted),
            "guests_muted": \(status.guestsMuted),
            "presentation_allowed": \(status.presentationAllowed),
            "direct_media": \(status.directMedia),
            "live_captions_available": \(status.liveCaptionsAvailable)
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        let decodedStatus = try JSONDecoder().decode(
            ConferenceStatus.self,
            from: data
        )

        XCTAssertEqual(decodedStatus, status)
    }

    func testDecodingWithEmptyJSONObject() throws {
        let json = "{}"
        let data = try XCTUnwrap(json.data(using: .utf8))
        let decodedStatus = try JSONDecoder().decode(
            ConferenceStatus.self,
            from: data
        )

        XCTAssertFalse(decodedStatus.started)
        XCTAssertFalse(decodedStatus.locked)
        XCTAssertFalse(decodedStatus.allMuted)
        XCTAssertFalse(decodedStatus.guestsMuted)
        XCTAssertFalse(decodedStatus.presentationAllowed)
        XCTAssertFalse(decodedStatus.directMedia)
        XCTAssertFalse(decodedStatus.liveCaptionsAvailable)
    }
}
