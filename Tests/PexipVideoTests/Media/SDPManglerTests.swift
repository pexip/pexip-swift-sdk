import XCTest
@testable import PexipVideo

// swiftlint:disable type_body_length
final class SDPManglerTests: XCTestCase {
    private func mangle(_ sdp: SDP, bandwidth: UInt = 0, isPresentation: Bool = false) -> SDP {
        let magler = SDPMangler(sdp: String(describing: sdp))
        let outSDPString = magler.sdp(withBandwidth: bandwidth, isPresentation: isPresentation)
        return SDP(sdpString: outSDPString)
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

    // MARK: - Orientation tests

    func testSDPWithOrientationExtension() {
        let inSDP = SDP([
            "line1",
            "a=extmap:4 urn:3gpp:video-orientation",
            "line3"
        ])
        let expectedSDP = SDP([
            "line1",
            "line3"
        ])
        XCTAssertEqual(mangle(inSDP), expectedSDP)
    }

    // MARK: - Bandwidth tests

    func testSDPAddsBandwidthToVideoSectionAfterConnection() {
        let bandwidth: UInt = 123111
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
            "b=AS:\(bandwidth)",
            "line4"
        ])
        let outSDP = mangle(inSDP, bandwidth: bandwidth)
        XCTAssertEqual(outSDP, expectedSDP)
    }

    func testSDPNoBandwidthInAudioSectionAfterConnection() {
        let bandwidth: UInt = 123222
        let inSDP = SDP([
            "line1",
            "m=audio 64165 UDP/TLS/RTP/SAVPF 111 103 104 9 102 0 8 106 105 13 110 112 113 126",
            "c=IN IP4 91.240.204.48",
            "line4"
        ])
        let expectedSDP = inSDP
        let outSDP = mangle(inSDP, bandwidth: bandwidth)
        XCTAssertEqual(outSDP, expectedSDP)
    }

    func testSDPNoBandwidthWithoutMediaSectionAfterConnection() {
        let bandwidth: UInt = 123333
        let inSDP = SDP([
            "line1",
            "c=IN IP4 91.240.204.48",
            "line3"
        ])
        let expectedSDP = inSDP
        let outSDP = mangle(inSDP, bandwidth: bandwidth)
        XCTAssertEqual(outSDP, expectedSDP)
    }

    func testAddsBandwidthToVideoSectionAfterConnectionWithAudioSectionFirst() {
        let bandwidth: UInt = 123444
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
            "b=AS:\(bandwidth)",
            "line7"
        ])
        let outSDP = mangle(inSDP, bandwidth: bandwidth)
        XCTAssertEqual(outSDP, expectedSDP)
    }

    func testNoBandwidthInVideoSectionWithoutConnection() {
        let bandwidth: UInt = 123555
        let inSDP = SDP([
            "line1",
            "m=video 64164 UDP/TLS/RTP/SAVPF 96 97 98 99 100 101 127",
            "line3"
        ])
        let expectedSDP = inSDP
        let outSDP = mangle(inSDP, bandwidth: bandwidth)
        XCTAssertEqual(outSDP, expectedSDP)
    }

    func testNoBandwidthInVideoSectionWithoutConnectionWithAudioSectionLast() {
        let bandwidth: UInt = 123666
        let inSDP = SDP([
            "line1",
            "m=video 64164 UDP/TLS/RTP/SAVPF 96 97 98 99 100 101 127",
            "line3",
            "m=audio 64165 UDP/TLS/RTP/SAVPF 111 103 104 9 102 0 8 106 105 13 110 112 113 126",
            "c=IN IP4 91.240.204.48",
            "line6"
        ])
        let expectedSDP = inSDP
        let outSDP = mangle(inSDP, bandwidth: bandwidth)
        XCTAssertEqual(outSDP, expectedSDP)
    }

    // MARK: - Presentation tests

    func testAddsPresentationToVideoSectionAfterConnection() {
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
            "a=content:slides",
            "line4"
        ])
        let outSDP = mangle(inSDP, isPresentation: true)
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
            "a=content:slides",
            "line7"
        ])
        let outSDP = mangle(inSDP, isPresentation: true)
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

    // MARK: - H264 Level hack tests

    func testH264Level52DegradesTo51() {
        let inSDP = SDP([
            "line1",
            "m=video 64164 UDP/TLS/RTP/SAVPF 96 97 98 99 100 101 127",
            "line3",
            "a=fmtp:96 level-asymmetry-allowed=1;packetization-mode=1;profile-level-id=640c34",
            "line5",
            "a=fmtp:98 level-asymmetry-allowed=1;packetization-mode=1;profile-level-id=42e034",
            "line7"
        ])
        let expectedSDP = SDP([
            "line1",
            "m=video 64164 UDP/TLS/RTP/SAVPF 96 97 98 99 100 101 127",
            "line3",
            "a=fmtp:96 level-asymmetry-allowed=1;packetization-mode=1;profile-level-id=640c33",
            "line5",
            "a=fmtp:98 level-asymmetry-allowed=1;packetization-mode=1;profile-level-id=42e033",
            "line7"
        ])
        let outSDP = mangle(inSDP)
        XCTAssertEqual(outSDP, expectedSDP)
    }

    func testH264Level3NoChange() {
        let inSDP = SDP([
            "line1",
            "m=video 64164 UDP/TLS/RTP/SAVPF 96 97 98 99 100 101 127",
            "line3",
            "a=fmtp:96 level-asymmetry-allowed=1;packetization-mode=1;profile-level-id=640c1f",
            "line5",
            "a=fmtp:98 level-asymmetry-allowed=1;packetization-mode=1;profile-level-id=42e01f",
            "line7"
        ])
        let expectedSDP = inSDP
        let outSDP = mangle(inSDP)
        XCTAssertEqual(outSDP, expectedSDP)
    }

    // MARK: - Combined tests

    func testAddsBandwidthAndPresentationToVideoSectionAfterConnection() {
        let bandwidth: UInt = 123777
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
            "b=AS:\(bandwidth)",
            "a=content:slides",
            "line4"
        ])
        let outSDP = mangle(inSDP, bandwidth: bandwidth, isPresentation: true)
        XCTAssertEqual(outSDP, expectedSDP)
    }

    func testAddsBandwidthAndPresentationToVideoSectionAfterConnectionAndExcludesOrientation() {
        let bandwidth: UInt = 123888
        let inSDP = SDP([
            "line1",
            "m=video 64164 UDP/TLS/RTP/SAVPF 96 97 98 99 100 101 127",
            "c=IN IP4 91.240.204.48",
            "line4",
            "a=extmap:4 urn:3gpp:video-orientation",
            "line6"
        ])
        let expectedSDP = SDP([
            "line1",
            "m=video 64164 UDP/TLS/RTP/SAVPF 96 97 98 99 100 101 127",
            "c=IN IP4 91.240.204.48",
            "b=AS:\(bandwidth)",
            "a=content:slides",
            "line4",
            "line6"
        ])
        let outSDP = mangle(inSDP, bandwidth: bandwidth, isPresentation: true)
        XCTAssertEqual(outSDP, expectedSDP)
    }
}

// MARK: - Helper types

private struct SDP: CustomStringConvertible, Equatable {
    let lines: [String]

    init(_ lines: [String]) {
        self.lines = lines
    }

    init(sdpString: String) {
        self.lines = sdpString.isEmpty
            ? []
            : sdpString.components(separatedBy: SDPMangler.Constants.endOfLine)
    }

    var description: String {
        lines.joined(separator: SDPMangler.Constants.endOfLine)
    }
}
