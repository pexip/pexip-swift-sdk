import XCTest
@testable import PexipVideo

final class ParticipantTests: XCTestCase {
    // swiftlint:disable function_body_length
    func testDecoding() throws {
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
            "uuid": "50b956c8-9a63-4711-8630-3810f8666b04",
            "vendor": "Pexip Infinity Connect/2.0.0-25227.0.0 (Windows NT 6.1; WOW64) nwjs/0.12.2 Chrome/41.0.2272.76"
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        let participant = try JSONDecoder().decode(Participant.self, from: data)
        let expectedParticipant = Participant(
            id: try XCTUnwrap(UUID(uuidString: "50b956c8-9a63-4711-8630-3810f8666b04")),
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
            startTime: 1441720992,
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
            isMuted: false,
            isPresenting: false,
            isVideoCall: true,
            isMuteSupported: true,
            isTransferSupported: true
        )

        XCTAssertEqual(participant, expectedParticipant)
    }
}
