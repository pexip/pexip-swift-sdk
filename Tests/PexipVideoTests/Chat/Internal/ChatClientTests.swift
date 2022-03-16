import XCTest
@testable import PexipVideo

final class ChatClientTests: APIClientTestCase<ChatClientProtocol> {
    func testSendChatMessage() async throws {
        let token = Token.randomToken()
        let message = "Test message"
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
        let result = try await client.sendChatMessage(message)

        // 3. Assert request
        let expectedUrlString = "\(nodeAddress)/api/client/v2/conferences/\(alias.uri)/message"
        let parameters = try JSONDecoder().decode(
            [String: String].self,
            from: try XCTUnwrap(createdRequest?.httpBody)
        )

        XCTAssertEqual(createdRequest?.url, try XCTUnwrap(URL(string: expectedUrlString)))
        XCTAssertEqual(createdRequest?.httpMethod, "POST")
        XCTAssertEqual(parameters["type"], "text/plain")
        XCTAssertEqual(parameters["payload"], message)
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
