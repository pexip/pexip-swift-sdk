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

final class ParticipantTests: XCTestCase {
    // swiftlint:disable function_body_length
    func testDecoding() throws {
        let id = "50b956c8-9a63-4711-8630-3810f8666b04"
        let json = """
        {
            "buzz_time": 0,
            "call_direction": "in",
            "call_tag": "def456",
            "disconnect_supported": "YES",
            "display_name": "Alice",
            "encryption": "On",
            "external_node_uuid": "",
            "fecc_supported": "NO",
            "has_media": false,
            "is_audio_only_call": "NO",
            "is_external": false,
            "is_muted": "NO",
            "is_presenting": "NO",
            "is_streaming_conference": false,
            "is_video_call": "YES",
            "is_video_muted": false,
            "local_alias": "meet.alice",
            "mute_supported": "YES",
            "overlay_text": "Alice",
            "presentation_supported": "NO",
            "protocol": "api",
            "role": "chair",
            "rx_presentation_policy": "ALLOW",
            "service_type": "conference",
            "spotlight": 0,
            "start_time": 1441720992,
            "transfer_supported": "YES",
            "uri": "Infinity_Connect_10.44.21.35",
            "uuid": "\(id)",
            "vendor": "Pexip Infinity Connect/2.0.0-25227.0.0 (Windows NT 6.1; WOW64) nwjs/0.12.2 Chrome/41.0.2272.76"
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        let participant = try JSONDecoder().decode(Participant.self, from: data)
        let expectedParticipant = Participant(
            id: id,
            displayName: "Alice",
            localAlias: "meet.alice",
            overlayText: "Alice",
            role: .chair,
            serviceType: .conference,
            buzzTime: 0,
            callDirection: .inbound,
            callTag: "def456",
            externalNodeId: "",
            callProtocol: "api",
            spotlightTime: 0,
            startTime: 1_441_720_992,
            uri: "Infinity_Connect_10.44.21.35",
            vendor: "Pexip Infinity Connect/2.0.0-25227.0.0 (Windows NT 6.1; WOW64) nwjs/0.12.2 Chrome/41.0.2272.76",
            hasMedia: false,
            isExternal: false,
            isStreamingConference: false,
            isVideoMuted: false,
            canReceivePresentation: true,
            isConnectionEncrypted: true,
            isDisconnectSupported: true,
            isFeccSupported: false,
            isAudioOnlyCall: false,
            isAudioMuted: false,
            isPresenting: false,
            isVideoCall: true,
            isMuteSupported: true,
            isTransferSupported: true
        )

        XCTAssertEqual(participant, expectedParticipant)
    }

    func testInit1() {
        let id = UUID().uuidString
        let participant = Participant(
            id: id,
            displayName: "Test",
            role: .chair,
            serviceType: .conference,
            callDirection: .inbound,
            hasMedia: true,
            isExternal: false,
            isStreamingConference: false,
            isVideoMuted: false,
            canReceivePresentation: true,
            isConnectionEncrypted: true,
            isDisconnectSupported: true,
            isFeccSupported: false,
            isAudioOnlyCall: false,
            isAudioMuted: false,
            isPresenting: false,
            isVideoCall: false,
            isMuteSupported: true,
            isTransferSupported: true
        )

        XCTAssertEqual(participant.id, id)
        XCTAssertEqual(participant.displayName, "Test")
        XCTAssertTrue(participant.localAlias.isEmpty)
        XCTAssertTrue(participant.overlayText.isEmpty)
        XCTAssertEqual(participant.role, .chair)
        XCTAssertEqual(participant.serviceType, .conference)
        XCTAssertEqual(participant.buzzTime, 0)
        XCTAssertEqual(participant.callDirection, .inbound)
        XCTAssertNil(participant.callTag)
        XCTAssertNil(participant.externalNodeId)
        XCTAssertNil(participant.callProtocol)
        XCTAssertEqual(participant.spotlightTime, 0)
        XCTAssertNil(participant.startTime)
        XCTAssertNil(participant.uri)
        XCTAssertNil(participant.vendor)
        XCTAssertTrue(participant.hasMedia)
        XCTAssertFalse(participant.isExternal)
        XCTAssertFalse(participant.isStreamingConference)
        XCTAssertFalse(participant.isVideoMuted)
        XCTAssertTrue(participant.canReceivePresentation)
        XCTAssertTrue(participant.isConnectionEncrypted)
        XCTAssertTrue(participant.isDisconnectSupported)
        XCTAssertFalse(participant.isFeccSupported)
        XCTAssertFalse(participant.isAudioOnlyCall)
        XCTAssertFalse(participant.isAudioMuted)
        XCTAssertFalse(participant.isPresenting)
        XCTAssertFalse(participant.isVideoCall)
        XCTAssertTrue(participant.isMuteSupported)
        XCTAssertTrue(participant.isTransferSupported)
    }

    func testInit2() {
        let id = UUID().uuidString
        let participant = Participant(
            id: id,
            displayName: "Test",
            role: .chair,
            serviceType: .conference,
            callDirection: .inbound,
            hasMedia: false,
            isExternal: true,
            isStreamingConference: true,
            isVideoMuted: true,
            canReceivePresentation: false,
            isConnectionEncrypted: false,
            isDisconnectSupported: false,
            isFeccSupported: true,
            isAudioOnlyCall: true,
            isAudioMuted: true,
            isPresenting: true,
            isVideoCall: true,
            isMuteSupported: false,
            isTransferSupported: false
        )

        XCTAssertEqual(participant.id, id)
        XCTAssertEqual(participant.displayName, "Test")
        XCTAssertTrue(participant.localAlias.isEmpty)
        XCTAssertTrue(participant.overlayText.isEmpty)
        XCTAssertEqual(participant.role, .chair)
        XCTAssertEqual(participant.serviceType, .conference)
        XCTAssertEqual(participant.buzzTime, 0)
        XCTAssertEqual(participant.callDirection, .inbound)
        XCTAssertNil(participant.callTag)
        XCTAssertNil(participant.externalNodeId)
        XCTAssertNil(participant.callProtocol)
        XCTAssertEqual(participant.spotlightTime, 0)
        XCTAssertNil(participant.startTime)
        XCTAssertNil(participant.uri)
        XCTAssertNil(participant.vendor)
        XCTAssertFalse(participant.hasMedia)
        XCTAssertTrue(participant.isExternal)
        XCTAssertTrue(participant.isStreamingConference)
        XCTAssertTrue(participant.isVideoMuted)
        XCTAssertFalse(participant.canReceivePresentation)
        XCTAssertFalse(participant.isConnectionEncrypted)
        XCTAssertFalse(participant.isDisconnectSupported)
        XCTAssertTrue(participant.isFeccSupported)
        XCTAssertTrue(participant.isAudioOnlyCall)
        XCTAssertTrue(participant.isAudioMuted)
        XCTAssertTrue(participant.isPresenting)
        XCTAssertTrue(participant.isVideoCall)
        XCTAssertFalse(participant.isMuteSupported)
        XCTAssertFalse(participant.isTransferSupported)
    }
}
