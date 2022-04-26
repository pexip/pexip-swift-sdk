import XCTest
@testable import PexipInfinityClient

final class CallServiceTests: XCTestCase {
    private let baseURL = URL(string: "https://example.com/participants/1/calls/1")!
    private var service: CallService!

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolMock.self]

        service = DefaultCallService(
            baseURL: baseURL,
            client: HTTPClient(session: URLSession(configuration: configuration))
        )
    }

    // MARK: - Tests

    func testNewCandidate() async throws {
        let token = Token.randomToken()
        let iceCandidate = IceCandidate(
            candidate: "candidate",
            mid: "mid",
            ufrag: "ufrag",
            pwd: "pwd"
        )
        var createdRequest: URLRequest?

        // 1. Mock response
        URLProtocolMock.makeResponse = { request in
            createdRequest = request
            return .http(
                statusCode: 200,
                data: Data(),
                headers: ["Content-Type": "application/json"]
            )
        }

        // 2. Make request
        try await service.newCandidate(iceCandidate: iceCandidate, token: token)

        // 3. Assert request
        let expectedURL = baseURL.appendingPathComponent("new_candidate")

        XCTAssertEqual(createdRequest?.url, expectedURL)
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

    func testAck() async throws {
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
        let result = try await service.ack(token: token)

        // 3. Assert request
        let expectedURL = baseURL.appendingPathComponent("ack")

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

    func testUpdate() async throws {

    }

    func testDisconnect() async throws {
        let token = Token.randomToken()
        var createdRequest: URLRequest?

        // 1. Mock response
        URLProtocolMock.makeResponse = { request in
            createdRequest = request
            return .http(
                statusCode: 200,
                data: Data(),
                headers: nil
            )
        }

        // 2. Make request
        try await service.disconnect(token: token)

        // 3. Assert request
        let expectedURL = baseURL.appendingPathComponent("disconnect")

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
    }
}
