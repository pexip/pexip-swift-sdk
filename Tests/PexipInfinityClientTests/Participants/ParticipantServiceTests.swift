//
// Copyright 2022-2024 Pexip AS
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

final class ParticipantServiceTests: APITestCase {
    private let baseURL = URL(string: "https://example.com/participants/1")!
    private var service: ParticipantService!
    private let responseJSON = """
        {
            "status": "success",
            "result": true
        }
        """

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        service = DefaultParticipantService(baseURL: baseURL, client: client)
    }

    // MARK: - Tests

    func testCalls() async throws {
        let token = ConferenceToken.randomToken()
        let callId = UUID().uuidString.lowercased()
        let inputSDP = UUID().uuidString
        let outputSDP = UUID().uuidString
        let fields = CallsFields(callType: "WEBRTC", sdp: inputSDP, present: nil)
        let responseJSON = """
        {
            "status": "success",
            "result": {
                "sdp": "\(outputSDP)",
                "call_uuid": "\(callId)"
            }
        }
        """

        try await testJSONRequest(
            withMethod: .POST,
            url: baseURL.appendingPathComponent("calls"),
            token: token,
            body: try JSONEncoder().encode(fields),
            responseJSON: responseJSON,
            execute: {
                let callDetails = try await service.calls(fields: fields, token: token)
                XCTAssertEqual(callDetails, CallDetails(id: callId, sdp: outputSDP))
            }
        )
    }

    func testAvatarURL() throws {
        let expectedURL = baseURL.appendingPathComponent("avatar.jpg")
        XCTAssertEqual(service.avatarURL(), expectedURL)
    }

    func testMute() async throws {
        let token = ConferenceToken.randomToken()
        try await testJSONRequest(
            withMethod: .POST,
            url: baseURL.appendingPathComponent("mute"),
            token: token,
            body: nil,
            responseJSON: responseJSON,
            execute: {
                let result = try await service.mute(token: token)
                XCTAssertTrue(result)
            }
        )
    }

    func testUnmute() async throws {
        let token = ConferenceToken.randomToken()
        try await testJSONRequest(
            withMethod: .POST,
            url: baseURL.appendingPathComponent("unmute"),
            token: token,
            body: nil,
            responseJSON: responseJSON,
            execute: {
                let result = try await service.unmute(token: token)
                XCTAssertTrue(result)
            }
        )
    }

    func testVideoMuted() async throws {
        let token = ConferenceToken.randomToken()
        try await testJSONRequest(
            withMethod: .POST,
            url: baseURL.appendingPathComponent("video_muted"),
            token: token,
            body: nil,
            responseJSON: responseJSON,
            execute: {
                let result = try await service.videoMuted(token: token)
                XCTAssertTrue(result)
            }
        )
    }

    func testVideoUnmuted() async throws {
        let token = ConferenceToken.randomToken()
        try await testJSONRequest(
            withMethod: .POST,
            url: baseURL.appendingPathComponent("video_unmuted"),
            token: token,
            body: nil,
            responseJSON: responseJSON,
            execute: {
                let result = try await service.videoUnmuted(token: token)
                XCTAssertTrue(result)
            }
        )
    }

    func testTakeFloor() async throws {
        let token = ConferenceToken.randomToken()
        try await testJSONRequest(
            withMethod: .POST,
            url: baseURL.appendingPathComponent("take_floor"),
            token: token,
            body: nil,
            responseJSON: responseJSON,
            execute: {
                try await service.takeFloor(token: token)
            }
        )
    }

    func testReleaseFloor() async throws {
        let token = ConferenceToken.randomToken()
        try await testJSONRequest(
            withMethod: .POST,
            url: baseURL.appendingPathComponent("release_floor"),
            token: token,
            body: nil,
            responseJSON: responseJSON,
            execute: {
                try await service.releaseFloor(token: token)
            }
        )
    }

    func testShowLiveCaptions() async throws {
        let token = ConferenceToken.randomToken()
        try await testJSONRequest(
            withMethod: .POST,
            url: baseURL.appendingPathComponent("show_live_captions"),
            token: token,
            body: nil,
            responseJSON: responseJSON,
            execute: {
                try await service.showLiveCaptions(token: token)
            }
        )
    }

    func testHideLiveCaptions() async throws {
        let token = ConferenceToken.randomToken()
        try await testJSONRequest(
            withMethod: .POST,
            url: baseURL.appendingPathComponent("hide_live_captions"),
            token: token,
            body: nil,
            responseJSON: responseJSON,
            execute: {
                try await service.hideLiveCaptions(token: token)
            }
        )
    }

    func testToggleLiveCaptions() async throws {
        let token = ConferenceToken.randomToken()

        // Enabled = true
        try await testJSONRequest(
            withMethod: .POST,
            url: baseURL.appendingPathComponent("show_live_captions"),
            token: token,
            body: nil,
            responseJSON: responseJSON,
            execute: {
                try await service.toggleLiveCaptions(true, token: token)
            }
        )

        // Enabled = false
        try await testJSONRequest(
            withMethod: .POST,
            url: baseURL.appendingPathComponent("hide_live_captions"),
            token: token,
            body: nil,
            responseJSON: responseJSON,
            execute: {
                try await service.toggleLiveCaptions(false, token: token)
            }
        )
    }

    func testDtmf() async throws {
        let dtmf = try XCTUnwrap(DTMFSignals(rawValue: "1234"))
        let token = ConferenceToken.randomToken()
        try await testJSONRequest(
            withMethod: .POST,
            url: baseURL.appendingPathComponent("dtmf"),
            token: token,
            body: JSONEncoder().encode([
                "digits": dtmf.rawValue
            ]),
            responseJSON: responseJSON,
            execute: {
                let result = try await service.dtmf(signals: dtmf, token: token)
                XCTAssertTrue(result)
            }
        )
    }

    func testPreferredAspectRatio() async throws {
        let token = ConferenceToken.randomToken()

        func request(_ aspectRatio: Float) async throws {
            try await testJSONRequest(
                withMethod: .POST,
                url: baseURL.appendingPathComponent("preferred_aspect_ratio"),
                token: token,
                body: JSONEncoder().encode([
                    "aspect_ratio": aspectRatio
                ]),
                responseJSON: responseJSON,
                execute: {
                    let result = try await service.preferredAspectRatio(
                        aspectRatio,
                        token: token
                    )
                    XCTAssertTrue(result)
                }
            )
        }

        try await request(9 / 16)

        do {
            try await request(3)
            XCTFail("Should throw an error")
        } catch {
            XCTAssertEqual(error as? ParticipantError, .invalidAspectRatio)
        }
    }

    func testCall() throws {
        let id = UUID().uuidString.lowercased()
        let service = service.call(id: id) as? DefaultCallService

        XCTAssertEqual(
            service?.baseURL,
            baseURL
                .appendingPathComponent("calls")
                .appendingPathComponent(id)
        )
    }
}
