import XCTest
import PexipMedia
@testable import PexipRTC

final class SessionDescriptionManagerTests: XCTestCase {
    private func mangle(
        _ sdp: SDP,
        bandwidth: Bandwidth = .high,
        profile: QualityProfile = .medium,
        mainAudioMid: String? = nil,
        mainVideoMid: String? = nil,
        presentationVideoMid: String? = nil
    ) -> SDP {
        let manager = SessionDescriptionManager(sdp: sdp.string)
        let outSDPString = manager.mangle(
            bandwidth: bandwidth,
            mainQualityProfile: profile,
            mainAudioMid: mainAudioMid,
            mainVideoMid: mainVideoMid,
            presentationVideoMid: presentationVideoMid
        )
        return SDP(string: outSDPString)
    }

    // MARK: - Generic tests

    func testSDPWithNoChanges() {
        let inSDP = SDP([
            "line1",
            "line2"
        ])
        let expectedSDP = inSDP
        XCTAssertEqual(mangle(inSDP), expectedSDP)
    }

    func testSDPWithEmptyString() {
        let inSDP = SDP([])
        let expectedSDP = inSDP
        XCTAssertEqual(mangle(inSDP), expectedSDP)
    }

    // MARK: - Combined tests

    func testMangleWithMidLines() {
        let profile = QualityProfile.medium
        let bandwidth = Bandwidth.medium
        let inSDP = SDP([
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
        ])
        let expectedSDP = SDP([
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
            "b=AS:\(bandwidth.rawValue)",

            "a=mid:5",
            "a=content:slides",
            "a=extmap:14 urn:ietf:params:rtp-hdrext:toffset",
            "m=video 64164 UDP/TLS/RTP/SAVPF 96 97 98 99 100 101 127",
            "c=IN IP4 91.240.204.48"
        ])
        let outSDP = mangle(
            inSDP,
            bandwidth: bandwidth,
            profile: profile,
            mainAudioMid: "3",
            mainVideoMid: "4",
            presentationVideoMid: "5"
        )

        XCTAssertEqual(outSDP, expectedSDP)
    }

    // MARK: - Bandwidth tests

    func testSDPAddsBandwidthToVideoSectionAfterConnection() {
        let profile = QualityProfile.high
        let bandwidth = Bandwidth.high
        let inSDP = SDP([
            "line1",
            "m=video 64164 UDP/TLS/RTP/SAVPF 96 97 98 99 100 101 127",
            "c=IN IP4 91.240.204.48",
            "line4"
        ])
        let expectedSDP = SDP([
            "line1",
            "m=video 64164 UDP/TLS/RTP/SAVPF 96 97 98 99 100 101 127",
            "c=IN IP4 91.240.204.48",
            "b=AS:\(bandwidth.rawValue)",
            "line4"
        ])
        let outSDP = mangle(inSDP, bandwidth: bandwidth, profile: profile)
        XCTAssertEqual(outSDP, expectedSDP)
    }

    func testSDPNoBandwidthInAudioSectionAfterConnection() {
        let profile = QualityProfile.high
        let inSDP = SDP([
            "line1",
            "m=audio 64165 UDP/TLS/RTP/SAVPF 111 103 104 9 102 0 8 106 105 13 110 112 113 126",
            "c=IN IP4 91.240.204.48",
            "line4"
        ])
        let expectedSDP = inSDP
        let outSDP = mangle(inSDP, profile: profile)
        XCTAssertEqual(outSDP, expectedSDP)
    }

    func testSDPNoBandwidthWithoutMediaSectionAfterConnection() {
        let profile = QualityProfile.high
        let inSDP = SDP([
            "line1",
            "c=IN IP4 91.240.204.48",
            "line3"
        ])
        let expectedSDP = inSDP
        let outSDP = mangle(inSDP, profile: profile)
        XCTAssertEqual(outSDP, expectedSDP)
    }

    func testAddsBandwidthToVideoSectionAfterConnectionWithAudioSectionFirst() {
        let profile = QualityProfile.medium
        let bandwidth = Bandwidth.medium
        let inSDP = SDP([
            "line1",
            "m=audio 64165 UDP/TLS/RTP/SAVPF 111 103 104 9 102 0 8 106 105 13 110 112 113 126",
            "c=IN IP4 91.240.204.48",
            "line4",
            "m=video 64164 UDP/TLS/RTP/SAVPF 96 97 98 99 100 101 127",
            "c=IN IP4 91.240.204.48",
            "line7"
        ])
        let expectedSDP = SDP([
            "line1",
            "m=audio 64165 UDP/TLS/RTP/SAVPF 111 103 104 9 102 0 8 106 105 13 110 112 113 126",
            "c=IN IP4 91.240.204.48",
            "line4",
            "m=video 64164 UDP/TLS/RTP/SAVPF 96 97 98 99 100 101 127",
            "c=IN IP4 91.240.204.48",
            "b=AS:\(bandwidth.rawValue)",
            "line7"
        ])
        let outSDP = mangle(inSDP, bandwidth: bandwidth, profile: profile)
        XCTAssertEqual(outSDP, expectedSDP)
    }

    func testNoBandwidthInVideoSectionWithoutConnection() {
        let profile = QualityProfile.high
        let inSDP = SDP([
            "line1",
            "m=video 64164 UDP/TLS/RTP/SAVPF 96 97 98 99 100 101 127",
            "line3"
        ])
        let expectedSDP = inSDP
        let outSDP = mangle(inSDP, profile: profile)
        XCTAssertEqual(outSDP, expectedSDP)
    }

    func testNoBandwidthInVideoSectionWithoutConnectionWithAudioSectionLast() {
        let profile = QualityProfile.high
        let inSDP = SDP([
            "line1",
            "m=video 64164 UDP/TLS/RTP/SAVPF 96 97 98 99 100 101 127",
            "line3",
            "m=audio 64165 UDP/TLS/RTP/SAVPF 111 103 104 9 102 0 8 106 105 13 110 112 113 126",
            "c=IN IP4 91.240.204.48",
            "line6"
        ])
        let expectedSDP = inSDP
        let outSDP = mangle(inSDP, profile: profile)
        XCTAssertEqual(outSDP, expectedSDP)
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
