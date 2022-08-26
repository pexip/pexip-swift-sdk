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
                let result = try await service.ack(token: token)
                XCTAssertTrue(result)
            })
    }

    func testUpdate() async throws {
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
