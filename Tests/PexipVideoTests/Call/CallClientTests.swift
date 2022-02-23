import XCTest
@testable import PexipVideo

final class CallClientTests: APIClientTestCase<CallClientProtocol> {
    // swiftlint:disable function_body_length
    func testMakeCall() async throws {
        let token = Token.randomToken()
        let participantId = UUID()
        let callId = UUID()
        let inputSDP = UUID().uuidString
        let presentation: CallPresentationKind = .receive
        let outputSDP = UUID().uuidString
        let json = """
        {
            "status": "success",
            "result": {
                "sdp": "\(outputSDP)",
                "call_uuid": "\(callId.uuidString.lowercased())"
            }
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        var createdRequest: URLRequest?

        // 1. Mock response
        tokenProvider.token = token

        URLProtocolMock.makeResponse = { request in
            createdRequest = request
            return .init(
                statusCode: 200,
                data: data,
                headerFields: ["Content-Type": "application/json"]
            )
        }

        // 2. Make request
        let callDetails = try await client.makeCall(
            participantId: participantId,
            sdp: inputSDP,
            presentation: presentation
        )

        // 3. Assert request
        let expectedUrlString = "\(nodeAddress)/api/client/v2/conferences/\(alias.uri)/"
            + "participants/\(participantId.uuidString.lowercased())/"
            + "calls"
        let parameters = try JSONDecoder().decode(
            [String: String].self,
            from: try XCTUnwrap(createdRequest?.httpBody)
        )

        XCTAssertEqual(createdRequest?.url, try XCTUnwrap(URL(string: expectedUrlString)))
        XCTAssertEqual(createdRequest?.httpMethod, "POST")
        XCTAssertEqual(parameters["call_type"], "WEBRTC")
        XCTAssertEqual(parameters["sdp"], inputSDP)
        XCTAssertEqual(parameters["present"], presentation.rawValue)
        XCTAssertEqual(createdRequest?.timeoutInterval, 62)
        XCTAssertEqual(
            createdRequest?.value(forHTTPHeaderField: "Content-Type"),
            "application/json"
        )
        XCTAssertEqual(
            createdRequest?.value(forHTTPHeaderField: "User-Agent"),
            HTTPHeader.defaultUserAgent.value
        )
        XCTAssertEqual(
            createdRequest?.value(forHTTPHeaderField: "token"),
            token.value
        )

        // 4. Assert result
        XCTAssertEqual(callDetails, CallDetails(sdp: outputSDP, id: callId))
    }

    func testAck() async throws {
        let token = Token.randomToken()
        let participantId = UUID()
        let callId = UUID()
        let json = """
        {
            "status": "success",
            "result": true
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        var createdRequest: URLRequest?

        // 1. Mock response
        tokenProvider.token = token

        URLProtocolMock.makeResponse = { request in
            createdRequest = request
            return .init(
                statusCode: 200,
                data: data,
                headerFields: ["Content-Type": "application/json"]
            )
        }

        // 2. Make request
        let result = try await client.ack(participantId: participantId, callId: callId)

        // 3. Assert request
        let expectedUrlString = "\(nodeAddress)/api/client/v2/conferences/\(alias.uri)/"
            + "participants/\(participantId.uuidString.lowercased())/"
            + "calls/\(callId.uuidString.lowercased())/"
            + "ack"

        XCTAssertEqual(createdRequest?.url, try XCTUnwrap(URL(string: expectedUrlString)))
        XCTAssertEqual(createdRequest?.httpMethod, "POST")
        XCTAssertNil(createdRequest?.httpBody)
        XCTAssertEqual(
            createdRequest?.value(forHTTPHeaderField: "User-Agent"),
            HTTPHeader.defaultUserAgent.value
        )
        XCTAssertEqual(
            createdRequest?.value(forHTTPHeaderField: "token"),
            token.value
        )

        // 4. Assert result
        XCTAssertTrue(result)
    }

    func testDisconnect() async throws {
        let token = Token.randomToken()
        let participantId = UUID()
        let callId = UUID()
        var createdRequest: URLRequest?

        // 1. Mock response
        tokenProvider.token = token

        URLProtocolMock.makeResponse = { request in
            createdRequest = request
            return .init(
                statusCode: 200,
                data: Data()
            )
        }

        // 2. Make request
        try await client.disconnect(participantId: participantId, callId: callId)

        // 3. Assert request
        let expectedUrlString = "\(nodeAddress)/api/client/v2/conferences/\(alias.uri)/"
            + "participants/\(participantId.uuidString.lowercased())/"
            + "calls/\(callId.uuidString.lowercased())/"
            + "disconnect"

        XCTAssertEqual(createdRequest?.url, try XCTUnwrap(URL(string: expectedUrlString)))
        XCTAssertEqual(createdRequest?.httpMethod, "POST")
        XCTAssertNil(createdRequest?.httpBody)
        XCTAssertEqual(
            createdRequest?.value(forHTTPHeaderField: "User-Agent"),
            HTTPHeader.defaultUserAgent.value
        )
        XCTAssertEqual(
            createdRequest?.value(forHTTPHeaderField: "token"),
            token.value
        )
    }

    func testNewCandidate() async throws {
        let token = Token.randomToken()
        let participantId = UUID()
        let callId = UUID()
        let iceCandidate = IceCandidate(candidate: "candidate", mid: "mid", pwd: "pwd")
        var createdRequest: URLRequest?

        // 1. Mock response
        tokenProvider.token = token

        URLProtocolMock.makeResponse = { request in
            createdRequest = request
            return .init(
                statusCode: 200,
                data: Data(),
                headerFields: ["Content-Type": "application/json"]
            )
        }

        // 2. Make request
        try await client.newCandidate(
            participantId: participantId,
            callId: callId,
            iceCandidate: iceCandidate
        )

        // 3. Assert request
        let expectedUrlString = "\(nodeAddress)/api/client/v2/conferences/\(alias.uri)/"
            + "participants/\(participantId.uuidString.lowercased())/"
            + "calls/\(callId.uuidString.lowercased())/"
            + "new_candidate"

        XCTAssertEqual(createdRequest?.url, try XCTUnwrap(URL(string: expectedUrlString)))
        XCTAssertEqual(createdRequest?.httpMethod, "POST")
        XCTAssertEqual(createdRequest?.httpBody, try JSONEncoder().encode(iceCandidate))
        XCTAssertEqual(
            createdRequest?.value(forHTTPHeaderField: "Content-Type"),
            "application/json"
        )
        XCTAssertEqual(
            createdRequest?.value(forHTTPHeaderField: "User-Agent"),
            HTTPHeader.defaultUserAgent.value
        )
        XCTAssertEqual(
            createdRequest?.value(forHTTPHeaderField: "token"),
            token.value
        )
    }
}
