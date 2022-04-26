import XCTest
@testable import PexipInfinityClient

final class ParticipantServiceTests: APITestCase {
    private let baseURL = URL(string: "https://example.com/participants/1")!
    private var service: ParticipantService!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        service = DefaultParticipantService(baseURL: baseURL, client: client)
    }

    // MARK: - Tests

    // swiftlint:disable function_body_length
    func testCalls() async throws {
        let token = Token.randomToken()
        let callId = UUID()
        let inputSDP = UUID().uuidString
        let outputSDP = UUID().uuidString
        let fields = CallsFields(callType: "WEBRTC", sdp: inputSDP, present: nil)
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
        let token = Token.randomToken()
        let responseJSON = """
        {
            "status": "success",
            "result": true
        }
        """
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
        let token = Token.randomToken()
        let responseJSON = """
        {
            "status": "success",
            "result": true
        }
        """
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
        let token = Token.randomToken()
        let responseJSON = """
        {
            "status": "success",
            "result": true
        }
        """
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
        let token = Token.randomToken()
        let responseJSON = """
        {
            "status": "success",
            "result": true
        }
        """
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
}
