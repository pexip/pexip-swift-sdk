import XCTest
@testable import PexipVideo

final class ParticipantClientTests: APIClientTestCase<ParticipantClientProtocol> {
    func testAvatarURL() throws {
        let id = UUID()
        let expectedUrlString = "\(nodeAddress)/api/client/v2/conferences/\(alias.uri)/"
            + "participants/\(id.uuidString.lowercased())/"
            + "avatar.jpg"
        let expectedURL = try XCTUnwrap(URL(string: expectedUrlString))

        XCTAssertEqual(client.avatarURL(participantId: id), expectedURL)
    }

    func testMuteVideo() async throws {
        let token = Token.randomToken()
        let participantId = UUID()
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
            return .http(
                statusCode: 200,
                data: data,
                headers: ["Content-Type": "application/json"]
            )
        }

        // 2. Make request
        let result = try await client.muteVideo(participantId: participantId)

        // 3. Assert request
        let expectedUrlString = "\(nodeAddress)/api/client/v2/conferences/\(alias.uri)/"
            + "participants/\(participantId.uuidString.lowercased())/"
            + "video_muted"

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

    func testUnmuteVideo() async throws {
        let token = Token.randomToken()
        let participantId = UUID()
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
            return .http(
                statusCode: 200,
                data: data,
                headers: ["Content-Type": "application/json"]
            )
        }

        // 2. Make request
        let result = try await client.unmuteVideo(participantId: participantId)

        // 3. Assert request
        let expectedUrlString = "\(nodeAddress)/api/client/v2/conferences/\(alias.uri)/"
            + "participants/\(participantId.uuidString.lowercased())/"
            + "video_unmuted"

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
}
