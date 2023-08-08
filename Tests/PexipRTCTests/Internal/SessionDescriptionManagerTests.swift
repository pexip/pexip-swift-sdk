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
import PexipMedia
@testable import PexipRTC

final class SessionDescriptionManagerTests: XCTestCase {
    func testMangleWithNoChanges() {
        let original = SDP([
            "line1",
            "line2"
        ]).string

        let mangled = SessionDescriptionManager(sdp: original).mangle(
            bitrate: Bitrate.bps(0)
        )

        XCTAssertEqual(mangled, original)
    }

    func testMangleWithEmptyString() {
        let original = ""
        let mangled = SessionDescriptionManager(sdp: original).mangle(
            bitrate: Bitrate.bps(0)
        )
        XCTAssertEqual(mangled, original)
    }

    func testMangleWithMidLinesAndBitrate() {
        let bitrate = Bitrate.kbps(576)!
        let original = SDP([
            "a=mid:3",
            "a=extmap:1 urn:ietf:params:rtp-hdrext:ssrc-audio-level",
            "m=audio 64165 UDP/TLS/RTP/SAVPF 111 103 104 9 102 0 8 106 105 13 110 112 113 126",
            "c=IN IP4 91.240.204.48",

            "a=mid:4",
            "a=extmap:14 urn:ietf:params:rtp-hdrext:toffset",
            "m=video 64164 UDP/TLS/RTP/SAVPF 96 97 98 99 100 101 127",
            "c=IN IP4 91.240.204.48",

            "a=mid:5",
            "a=extmap:14 urn:ietf:params:rtp-hdrext:toffset",
            "m=video 64164 UDP/TLS/RTP/SAVPF 96 97 98 99 100 101 127",
            "c=IN IP4 91.240.204.48"
        ]).string

        let expected = SDP([
            "a=mid:3",
            "a=content:main",
            "a=extmap:1 urn:ietf:params:rtp-hdrext:ssrc-audio-level",
            "m=audio 64165 UDP/TLS/RTP/SAVPF 111 103 104 9 102 0 8 106 105 13 110 112 113 126",
            "c=IN IP4 91.240.204.48",

            "a=mid:4",
            "a=content:main",
            "a=extmap:14 urn:ietf:params:rtp-hdrext:toffset",
            "m=video 64164 UDP/TLS/RTP/SAVPF 96 97 98 99 100 101 127",
            "c=IN IP4 91.240.204.48",
            "b=TIAS:\(bitrate.bps)",

            "a=mid:5",
            "a=content:slides",
            "a=extmap:14 urn:ietf:params:rtp-hdrext:toffset",
            "m=video 64164 UDP/TLS/RTP/SAVPF 96 97 98 99 100 101 127",
            "c=IN IP4 91.240.204.48",
            "b=TIAS:\(bitrate.bps)"
        ]).string

        let mangled = SessionDescriptionManager(sdp: original).mangle(
            bitrate: bitrate,
            mids: [
                .mainAudio: "3",
                .mainVideo: "4",
                .presentationVideo: "5"
            ]
        )

        XCTAssertEqual(mangled, expected)
    }

    func testMangleWithMidLinesAndZeroBitrate() {
        let bitrate = Bitrate.bps(0)
        let original = SDP([
            "a=mid:3",
            "a=extmap:1 urn:ietf:params:rtp-hdrext:ssrc-audio-level",
            "m=audio 64165 UDP/TLS/RTP/SAVPF 111 103 104 9 102 0 8 106 105 13 110 112 113 126",
            "c=IN IP4 91.240.204.48",

            "a=mid:4",
            "a=extmap:14 urn:ietf:params:rtp-hdrext:toffset",
            "m=video 64164 UDP/TLS/RTP/SAVPF 96 97 98 99 100 101 127",
            "c=IN IP4 91.240.204.48",

            "a=mid:5",
            "a=extmap:14 urn:ietf:params:rtp-hdrext:toffset",
            "m=video 64164 UDP/TLS/RTP/SAVPF 96 97 98 99 100 101 127",
            "c=IN IP4 91.240.204.48"
        ]).string

        let expected = SDP([
            "a=mid:3",
            "a=content:main",
            "a=extmap:1 urn:ietf:params:rtp-hdrext:ssrc-audio-level",
            "m=audio 64165 UDP/TLS/RTP/SAVPF 111 103 104 9 102 0 8 106 105 13 110 112 113 126",
            "c=IN IP4 91.240.204.48",

            "a=mid:4",
            "a=content:main",
            "a=extmap:14 urn:ietf:params:rtp-hdrext:toffset",
            "m=video 64164 UDP/TLS/RTP/SAVPF 96 97 98 99 100 101 127",
            "c=IN IP4 91.240.204.48",

            "a=mid:5",
            "a=content:slides",
            "a=extmap:14 urn:ietf:params:rtp-hdrext:toffset",
            "m=video 64164 UDP/TLS/RTP/SAVPF 96 97 98 99 100 101 127",
            "c=IN IP4 91.240.204.48"
        ]).string

        let mangled = SessionDescriptionManager(sdp: original).mangle(
            bitrate: bitrate,
            mids: [
                .mainAudio: "3",
                .mainVideo: "4",
                .presentationVideo: "5"
            ]
        )

        XCTAssertEqual(mangled, expected)
    }

    func testMangleBitrateWhenLowerThanOriginal() {
        let bitrate = Bitrate.kbps(576)!
        let original = SDP([
            "a=mid:4",
            "a=extmap:14 urn:ietf:params:rtp-hdrext:toffset",
            "m=video 64164 UDP/TLS/RTP/SAVPF 96 97 98 99 100 101 127",
            "c=IN IP4 91.240.204.48",
            "b=TIAS:3732480"
        ]).string

        let expected = SDP([
            "a=mid:4",
            "a=extmap:14 urn:ietf:params:rtp-hdrext:toffset",
            "m=video 64164 UDP/TLS/RTP/SAVPF 96 97 98 99 100 101 127",
            "c=IN IP4 91.240.204.48",
            "b=TIAS:\(bitrate.bps)"
        ]).string

        let mangled = SessionDescriptionManager(
            sdp: original
        ).mangle(bitrate: bitrate)

        XCTAssertEqual(mangled, expected)
    }

    func testMangleBitrateWhenHigherThanOriginal() {
        let bitrate = Bitrate.mbps(10)!
        let original = SDP([
            "a=mid:4",
            "a=extmap:14 urn:ietf:params:rtp-hdrext:toffset",
            "m=video 64164 UDP/TLS/RTP/SAVPF 96 97 98 99 100 101 127",
            "c=IN IP4 91.240.204.48",
            "b=TIAS:3732480"
        ]).string

        let mangled = SessionDescriptionManager(
            sdp: original
        ).mangle(bitrate: bitrate)

        XCTAssertEqual(mangled, original)
    }

    func testMangleBitrateWhenZero() {
        let bitrate = Bitrate.mbps(0)!
        let original = SDP([
            "a=mid:4",
            "a=extmap:14 urn:ietf:params:rtp-hdrext:toffset",
            "m=video 64164 UDP/TLS/RTP/SAVPF 96 97 98 99 100 101 127",
            "c=IN IP4 91.240.204.48",
            "b=TIAS:3732480"
        ]).string
        let mangled = SessionDescriptionManager(
            sdp: original
        ).mangle(bitrate: bitrate)

        XCTAssertEqual(mangled, original)
    }

    func testExtractFingerprints() {
        let sdp = SDP([
            "line1",
            "a=fingerprint:sha-256 hash1",
            "line3",
            "line4",
            "a=fingerprint:sha-256 hash2"
        ])

        let manager = SessionDescriptionManager(sdp: sdp.string)
        let fingerprints = manager.extractFingerprints()

        XCTAssertEqual(
            fingerprints,
            [
                Fingerprint(type: "sha-256", hash: "hash1"),
                Fingerprint(type: "sha-256", hash: "hash2")
            ]
        )
    }
}

// MARK: - Helper types

private struct SDP: Equatable {
    let string: String

    init(_ lines: [String]) {
        self.string = lines.joined(separator: "\r\n").appending("\r\n")
    }

    init(string: String) {
        self.string = string
    }
}
