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

final class ConferenceEventParserTests: XCTestCase {
    private var parser: ConferenceEventParser!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        parser = ConferenceEventParser()
    }

    // MARK: - Tests

    func testParseEventDataWithoutName() throws {
        let event = HTTPEvent(
            id: nil,
            name: nil,
            data: "",
            retry: nil
        )
        XCTAssertNil(parser.parseEventData(from: event))
    }

    func testParseEventDataWithoutData() throws {
        let event = HTTPEvent(
            id: "1",
            name: "message_received",
            data: nil,
            retry: nil
        )
        XCTAssertNil(parser.parseEventData(from: event))
    }

    func testParseEventDataWithInvalidData() throws {
        let event = HTTPEvent(
            id: "1",
            name: "message_received",
            data: "",
            retry: nil
        )
        XCTAssertNil(parser.parseEventData(from: event))
    }

    func testSplashScreen() throws {
        let expectedEvent = SplashScreenEvent(key: "direct_media")
        let httpEvent = try HTTPEvent.stub(for: expectedEvent, name: "splash_screen")

        switch parser.parseEventData(from: httpEvent) {
        case .splashScreen(let event):
            XCTAssertEqual(event, expectedEvent)
        default:
            XCTFail("Invalid event type")
        }
    }

    func testSplashScreenWithNull() throws {
        let httpEvent = HTTPEvent(
            id: "1",
            name: "splash_screen",
            data: "null",
            retry: nil
        )

        switch parser.parseEventData(from: httpEvent) {
        case .splashScreen(let event):
            XCTAssertNil(event)
        default:
            XCTFail("Invalid event type")
        }
    }

    func testConferenceUpdate() throws {
        let expectedStatus = ConferenceStatus(
            started: true,
            locked: false,
            allMuted: false,
            guestsMuted: false,
            presentationAllowed: true,
            directMedia: false,
            liveCaptionsAvailable: true
        )
        let httpEvent = try HTTPEvent.stub(for: expectedStatus, name: "conference_update")

        switch parser.parseEventData(from: httpEvent) {
        case .conferenceUpdate(let status):
            XCTAssertEqual(status, expectedStatus)
        default:
            XCTFail("Unexpected event type")
        }
    }

    func testMessageReceived() throws {
        let expectedMessage = ChatMessage(
            senderName: "User",
            senderId: UUID().uuidString,
            type: "message",
            payload: "Test"
        )
        let httpEvent = try HTTPEvent.stub(for: expectedMessage, name: "message_received")

        switch parser.parseEventData(from: httpEvent) {
        case .messageReceived(let message):
            XCTAssertEqual(message.senderName, expectedMessage.senderName)
            XCTAssertEqual(message.senderId, expectedMessage.senderId)
            XCTAssertEqual(message.type, expectedMessage.type)
            XCTAssertEqual(message.payload, expectedMessage.payload)
        default:
            XCTFail("Unexpected event type")
        }
    }

    func testNewOffer() throws {
        let expectedEvent = NewOfferMessage(sdp: UUID().uuidString)
        let httpEvent = try HTTPEvent.stub(for: expectedEvent, name: "new_offer")

        switch parser.parseEventData(from: httpEvent) {
        case .newOffer(let event):
            XCTAssertEqual(event, expectedEvent)
        default:
            XCTFail("Invalid event type")
        }
    }

    func testUpdateSdp() throws {
        let expectedEvent = UpdateSdpMessage(sdp: UUID().uuidString)
        let httpEvent = try HTTPEvent.stub(for: expectedEvent, name: "update_sdp")

        switch parser.parseEventData(from: httpEvent) {
        case .updateSdp(let event):
            XCTAssertEqual(event, expectedEvent)
        default:
            XCTFail("Invalid event type")
        }
    }

    func testNewCandidate() throws {
        let expectedEvent = IceCandidate(
            candidate: UUID().uuidString,
            mid: "0",
            ufrag: "ufrag",
            pwd: nil
        )
        let httpEvent = try HTTPEvent.stub(for: expectedEvent, name: "new_candidate")

        switch parser.parseEventData(from: httpEvent) {
        case .newCandidate(let event):
            XCTAssertEqual(event, expectedEvent)
        default:
            XCTFail("Invalid event type")
        }
    }

    func testPresentationStart() throws {
        let expectedEvent = PresentationStartEvent(
            presenterName: "Name",
            presenterUri: "URI"
        )
        let httpEvent = try HTTPEvent.stub(for: expectedEvent, name: "presentation_start")

        switch parser.parseEventData(from: httpEvent) {
        case .presentationStart(let event):
            XCTAssertEqual(event, expectedEvent)
        default:
            XCTFail("Invalid event type")
        }
    }

    func testPresentationStop() throws {
        let httpEvent = HTTPEvent(id: "1", name: "presentation_stop")
        let event = parser.parseEventData(from: httpEvent)
        XCTAssertEqual(event, .presentationStop)
    }

    func testParticipantSyncBegin() throws {
        let httpEvent = HTTPEvent(id: "1", name: "participant_sync_begin")
        let event = parser.parseEventData(from: httpEvent)
        XCTAssertEqual(event, .participantSyncBegin)
    }

    func testParticipantSyncEnd() throws {
        let httpEvent = HTTPEvent(id: "1", name: "participant_sync_end")
        let event = parser.parseEventData(from: httpEvent)
        XCTAssertEqual(event, .participantSyncEnd)
    }

    func testParticipantCreate() throws {
        let participant = Participant.stub(displayName: "Guest")
        let httpEvent = try HTTPEvent.stub(for: participant, name: "participant_create")
        let event = parser.parseEventData(from: httpEvent)
        XCTAssertEqual(event, .participantCreate(participant))
    }

    func testParticipantUpdate() throws {
        let participant = Participant.stub(displayName: "Guest")
        let httpEvent = try HTTPEvent.stub(for: participant, name: "participant_update")
        let event = parser.parseEventData(from: httpEvent)
        XCTAssertEqual(event, .participantUpdate(participant))
    }

    func testParticipantDelete() throws {
        let expectedEvent = ParticipantDeleteEvent(id: UUID().uuidString)
        let httpEvent = try HTTPEvent.stub(for: expectedEvent, name: "participant_delete")

        switch parser.parseEventData(from: httpEvent) {
        case .participantDelete(let event):
            XCTAssertEqual(event.id, expectedEvent.id)
        default:
            XCTFail("Invalid event type")
        }
    }

    func testPeerDisconnected() throws {
        let httpEvent = HTTPEvent(id: "11", name: "peer_disconnect")
        let event = parser.parseEventData(from: httpEvent)
        XCTAssertEqual(event, .peerDisconnected)
    }

    func testRefer() throws {
        let expectedEvent = ReferEvent(
            token: UUID().uuidString,
            alias: "conference@example.com"
        )
        let httpEvent = try HTTPEvent.stub(for: expectedEvent, name: "refer")

        switch parser.parseEventData(from: httpEvent) {
        case .refer(let event):
            XCTAssertEqual(event, expectedEvent)
        default:
            XCTFail("Invalid event type")
        }
    }

    func testCallDisconnected() throws {
        let expectedEvent = CallDisconnectEvent(callId: UUID().uuidString, reason: "Test")
        let httpEvent = try HTTPEvent.stub(for: expectedEvent, name: "call_disconnected")

        switch parser.parseEventData(from: httpEvent) {
        case .callDisconnected(let event):
            XCTAssertEqual(event, expectedEvent)
        default:
            XCTFail("Invalid event type")
        }
    }

    func testClientDisconnected() throws {
        let expectedEvent = ClientDisconnectEvent(reason: "Test")
        let httpEvent = try HTTPEvent.stub(for: expectedEvent, name: "disconnect")

        switch parser.parseEventData(from: httpEvent) {
        case .clientDisconnected(let event):
            XCTAssertEqual(event, expectedEvent)
        default:
            XCTFail("Invalid event type")
        }
    }

    func testLiveCaptions() throws {
        let expectedLiveCaptions = LiveCaptions(
            data: "Test",
            isFinal: true,
            sentAt: Date().timeIntervalSinceReferenceDate
        )
        let httpEvent = try HTTPEvent.stub(for: expectedLiveCaptions, name: "live_captions")

        switch parser.parseEventData(from: httpEvent) {
        case .liveCaptions(let liveCaptions):
            XCTAssertEqual(liveCaptions, expectedLiveCaptions)
        default:
            XCTFail("Unexpected event type")
        }
    }

    func testUnknown() throws {
        let httpEvent = try HTTPEvent.stub(
            for: ClientDisconnectEvent(reason: "Test"),
            name: "unknown"
        )
        let event = parser.parseEventData(from: httpEvent)
        XCTAssertNil(event)
    }
}
