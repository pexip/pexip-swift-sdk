import XCTest
@testable import PexipInfinityClient

final class ParticipantServiceTests: XCTestCase {
    private let baseURL = URL(string: "https://example.com/participants/1")!
    private var service: ParticipantService!

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolMock.self]

        service = DefaultParticipantService(
            baseURL: baseURL,
            client: HTTPClient(session: URLSession(configuration: configuration))
        )
    }

    // swiftlint:disable function_body_length
    func testCalls() async throws {
        let token = Token.randomToken()
        let callId = UUID()
        let inputSDP = UUID().uuidString
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
        URLProtocolMock.makeResponse = { request in
            createdRequest = request
            return .http(
                statusCode: 200,
                data: data,
                headers: ["Content-Type": "application/json"]
            )
        }

        // 2. Make request
        let fields = CallsFields(callType: "WEBRTC", sdp: inputSDP, present: nil)
        let callDetails = try await service.calls(fields: fields, token: token)

        // 3. Assert request
        let expectedURL = baseURL.appendingPathComponent("calls")
        let parameters = try JSONDecoder().decode(
            [String: String].self,
            from: try XCTUnwrap(createdRequest?.httpBody)
        )

        XCTAssertEqual(createdRequest?.url, expectedURL)
        XCTAssertEqual(createdRequest?.httpMethod, "POST")
        XCTAssertEqual(parameters["call_type"], "WEBRTC")
        XCTAssertEqual(parameters["sdp"], inputSDP)
        XCTAssertNil(parameters["present"])
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
        XCTAssertEqual(callDetails, CallDetails(id: callId, sdp: outputSDP))
    }

    func testAvatarURL() throws {
        let expectedURL = baseURL.appendingPathComponent("avatar.jpg")
        XCTAssertEqual(service.avatarURL(), expectedURL)
    }

    func testMuteVideo() async throws {
        let token = Token.randomToken()
        let json = """
        {
            "status": "success",
            "result": true
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        var createdRequest: URLRequest?

        // 1. Mock response
        URLProtocolMock.makeResponse = { request in
            createdRequest = request
            return .http(
                statusCode: 200,
                data: data,
                headers: ["Content-Type": "application/json"]
            )
        }

        // 2. Make request
        let result = try await service.videoMuted(token: token)

        // 3. Assert request
        let expectedURL = baseURL.appendingPathComponent("video_muted")

        XCTAssertEqual(createdRequest?.url, expectedURL)
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
        let json = """
        {
            "status": "success",
            "result": true
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        var createdRequest: URLRequest?

        // 1. Mock response
        URLProtocolMock.makeResponse = { request in
            createdRequest = request
            return .http(
                statusCode: 200,
                data: data,
                headers: ["Content-Type": "application/json"]
            )
        }

        // 2. Make request
        let result = try await service.videoUnmuted(token: token)

        // 3. Assert request
        let expectedURL = baseURL.appendingPathComponent("video_unmuted")

        XCTAssertEqual(createdRequest?.url, expectedURL)
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
