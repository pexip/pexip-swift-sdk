import XCTest
@testable import PexipVideo

// swiftlint:disable type_body_length
final class SDPManglerTests: XCTestCase {
    private func mangle(
        _ sdp: SDP,
        profile: QualityProfile = .medium,
        isPresentation: Bool = false
    ) -> SDP {
        let magler = SDPMangler(sdp: sdp.string)
        let outSDPString = magler.mangle(qualityProfile: profile, isPresentation: isPresentation)
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

    // MARK: - Bandwidth tests

    func testSDPAddsBandwidthToVideoSectionAfterConnection() {
        let profile = QualityProfile.high
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
            "b=AS:\(profile.bandwidth)",
            "line4"
        ])
        let outSDP = mangle(inSDP, profile: profile)
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
            "b=AS:\(profile.bandwidth)",
            "line7"
        ])
        let outSDP = mangle(inSDP, profile: profile)
        XCTAssertEqual(outSDP, expectedSDP)
    }

    func testNoBandwidthInVideoSectionWithoutConnection() {
        let profile = QualityProfile.veryHigh
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
        let profile = QualityProfile.veryHigh
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

    // MARK: - Presentation tests

    func testAddsPresentationToVideoSectionAfterConnection() {
        let profile = QualityProfile.low
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
            "b=AS:\(profile.bandwidth)",
            "a=content:slides",
            "line4"
        ])
        let outSDP = mangle(inSDP, profile: profile, isPresentation: true)
        XCTAssertEqual(outSDP, expectedSDP)
    }

    func testNoPresentationInAudioSectionAfterConnection() {
        let inSDP = SDP([
            "line1",
            "m=audio 64165 UDP/TLS/RTP/SAVPF 111 103 104 9 102 0 8 106 105 13 110 112 113 126",
            "c=IN IP4 91.240.204.48",
            "line4"
        ])
        let expectedSDP = inSDP
        let outSDP = mangle(inSDP, isPresentation: true)
        XCTAssertEqual(outSDP, expectedSDP)
    }

    func testNoPresentationWithoutMediaSectionAfterConnection() {
        let inSDP = SDP([
            "line1",
            "c=IN IP4 91.240.204.48",
            "line3"
        ])
        let expectedSDP = inSDP
        let outSDP = mangle(inSDP, isPresentation: true)
        XCTAssertEqual(outSDP, expectedSDP)
    }

    func testAddsPresentationToVideoSectionAfterConnectionWithAudioSectionFirst() {
        let profile = QualityProfile.medium
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
            "b=AS:\(profile.bandwidth)",
            "a=content:slides",
            "line7"
        ])
        let outSDP = mangle(inSDP, profile: profile, isPresentation: true)
        XCTAssertEqual(outSDP, expectedSDP)
    }

    func testNoPresentationInVideoSectionWithoutConnection() {
        let inSDP = SDP([
            "line1",
            "m=video 64164 UDP/TLS/RTP/SAVPF 96 97 98 99 100 101 127",
            "line3"
        ])
        let expectedSDP = inSDP
        let outSDP = mangle(inSDP, isPresentation: true)
        XCTAssertEqual(outSDP, expectedSDP)
    }

    func testNoPresentationInVideoSectionWithoutConnectionWithAudioSectionLast() {
        let inSDP = SDP([
            "line1",
            "m=video 64164 UDP/TLS/RTP/SAVPF 96 97 98 99 100 101 127",
            "line3",
            "m=audio 64165 UDP/TLS/RTP/SAVPF 111 103 104 9 102 0 8 106 105 13 110 112 113 126",
            "c=IN IP4 91.240.204.48",
            "line6"
        ])
        let expectedSDP = inSDP
        let outSDP = mangle(inSDP, isPresentation: true)
        XCTAssertEqual(outSDP, expectedSDP)
    }

    // MARK: - Opus bitrate tests

    func testSetsRtpmapOpusBitrate() throws {
        let profile = QualityProfile.veryHigh
        let opusBitrate = try XCTUnwrap(profile.opusBitrate) * 1000
        let inSDP = SDP([
            "line1",
            "m=video 64164 UDP/TLS/RTP/SAVPF 96 97 98 99 100 101 127",
            "c=IN IP4 91.240.204.48",
            "line4",
            "m=audio 9 RTP/SAVPF 109",
            "a=rtpmap:109 opus/48000/2",
            "a=fmtp:109 minptime=10;useinbandfec=1;maxaveragebitrate=131072;stereo=1;sprop-stereo=1;cbr=1",
            "line6"
        ])
        let expectedSDP = SDP([
            "line1",
            "m=video 64164 UDP/TLS/RTP/SAVPF 96 97 98 99 100 101 127",
            "c=IN IP4 91.240.204.48",
            "b=AS:\(profile.bandwidth)",
            "line4",
            "m=audio 9 RTP/SAVPF 109",
            "a=rtpmap:109 opus/48000/2",
            "a=fmtp:109 minptime=10;useinbandfec=1;maxaveragebitrate=\(opusBitrate);stereo=1;sprop-stereo=1;cbr=1",
            "line6"
        ])
        let outSDP = mangle(inSDP, profile: profile)
        XCTAssertEqual(outSDP, expectedSDP)
    }

    // MARK: - Combined tests

    func testAddsBandwidthAndPresentationToVideoSectionAfterConnection() {
        let profile = QualityProfile.veryHigh
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
            "b=AS:\(profile.bandwidth)",
            "a=content:slides",
            "line4"
        ])
        let outSDP = mangle(inSDP, profile: profile, isPresentation: true)
        XCTAssertEqual(outSDP, expectedSDP)
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
