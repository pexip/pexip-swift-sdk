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

final class CallServiceTests: APITestCase {
    private let baseURL = URL(string: "https://example.com/participants/1/calls/1")!
    private var service: CallService!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        service = DefaultCallService(baseURL: baseURL, client: client)
    }

    // MARK: - Tests

    func testNewCandidate() async throws {
        let token = ConferenceToken.randomToken()
        let iceCandidate = IceCandidate(
            candidate: "candidate",
            mid: "mid",
            ufrag: "ufrag",
            pwd: "pwd"
        )

        try await testJSONRequest(
            withMethod: .POST,
            url: baseURL.appendingPathComponent("new_candidate"),
            token: token,
            body: try JSONEncoder().encode(iceCandidate),
            responseJSON: nil,
            execute: {
                try await service.newCandidate(iceCandidate: iceCandidate, token: token)
            })
    }

    func testAck() async throws {
        let token = ConferenceToken.randomToken()
        let responseJSON = """
        {
            "status": "success",
            "result": true
        }
        """

        try await testJSONRequest(
            withMethod: .POST,
            url: baseURL.appendingPathComponent("ack"),
            token: token,
            body: nil,
            responseJSON: responseJSON,
            execute: {
                let result = try await service.ack(sdp: nil, token: token)
                XCTAssertTrue(result)
            })
    }

    func testAckWithSdp() async throws {
        let token = ConferenceToken.randomToken()
        let sdp = UUID().uuidString
        let responseJSON = """
        {
            "status": "success",
            "result": true
        }
        """

        try await testJSONRequest(
            withMethod: .POST,
            url: baseURL.appendingPathComponent("ack"),
            token: token,
            body: try JSONEncoder().encode(["sdp": sdp]),
            responseJSON: responseJSON,
            execute: {
                let result = try await service.ack(sdp: sdp, token: token)
                XCTAssertTrue(result)
            })
    }

    func testUpdateWithStringResponse() async throws {
        let token = ConferenceToken.randomToken()
        let sdp = "SDP"
        let responseJSON = """
        {
            "status": "success",
            "result": "New SDP"
        }
        """

        try await testJSONRequest(
            withMethod: .POST,
            url: baseURL.appendingPathComponent("update"),
            token: token,
            body: try JSONEncoder().encode(["sdp": sdp]),
            responseJSON: responseJSON,
            execute: {
                let newSdp = try await service.update(sdp: sdp, token: token)
                XCTAssertEqual(newSdp, "New SDP")
            })
    }

    func testUpdateWithDictionaryResponse() async throws {
        let token = ConferenceToken.randomToken()
        let inputSDP = "SDP"
        let callId = UUID()
        let outputSDP = UUID().uuidString
        let responseJSON = """
        {
            "status": "success",
            "result": {
                "sdp": "\(outputSDP)",
                "call_uuid": "\(callId.uuidString.lowercased())"
            }
        }
        """

        try await testJSONRequest(
            withMethod: .POST,
            url: baseURL.appendingPathComponent("update"),
            token: token,
            body: try JSONEncoder().encode(["sdp": inputSDP]),
            responseJSON: responseJSON,
            execute: {
                let newSdp = try await service.update(sdp: inputSDP, token: token)
                XCTAssertEqual(newSdp, outputSDP)
            })
    }

    func testDtmf() async throws {
        let dtmf = try XCTUnwrap(DTMFSignals(rawValue: "1234"))
        let token = ConferenceToken.randomToken()
        let responseJSON = """
            {
                "status": "success",
                "result": true
            }
            """

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

    func testDisconnect() async throws {
        let token = ConferenceToken.randomToken()
        try await testJSONRequest(
            withMethod: .POST,
            url: baseURL.appendingPathComponent("disconnect"),
            token: token,
            body: nil,
            responseJSON: nil,
            execute: {
                try await service.disconnect(token: token)
            })
    }
}
