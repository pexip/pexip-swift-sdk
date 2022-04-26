import XCTest
@testable import PexipInfinityClient

final class NodeServiceTests: XCTestCase {
    private let baseURL = URL(string: "https://example.com")!
    private var service: NodeService!

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolMock.self]

        service = DefaultNodeService(
            baseURL: baseURL,
            client: HTTPClient(session: URLSession(configuration: configuration))
        )
    }

    // MARK: - Tests

    /// In maintenance mode
    func testStatusWith503() async throws {
        var createdRequest: URLRequest?

        // 1. Mock response
        URLProtocolMock.makeResponse = { request in
            createdRequest = request
            return .http(statusCode: 503, data: Data(), headers: nil)
        }

        // 2. Make request
        let status = try await service.status()

        // 3. Assert request
        var expectedRequest = URLRequest(
            url: baseURL.appendingPathComponent("status"),
            httpMethod: .GET
        )
        expectedRequest.setHTTPHeader(.defaultUserAgent)
        XCTAssertEqual(createdRequest, expectedRequest)

        // 4. Assert result
        XCTAssertFalse(status)
    }

    /// Not in maintenance mode
    func testStatusWith200() async throws {
        // 1. Mock response
        URLProtocolMock.makeResponse = { _ in
            .http(statusCode: 200, data: Data(), headers: nil)
        }

        // 2. Make request
        let status = try await service.status()

        // 3. Assert result
        XCTAssertTrue(status)
    }

    func testStatusWith404() async throws {
        // 1. Mock response
        URLProtocolMock.makeResponse = { _ in
            .http(statusCode: 404, data: Data(), headers: nil)
        }

        // 2. Make request
        do {
            _ = try await service.status()
        } catch {
            XCTAssertEqual(error as? HTTPError, .resourceNotFound("Node"))
        }
    }

    func testStatusWith401() async throws {
        // 1. Mock response
        URLProtocolMock.makeResponse = { _ in
            .http(statusCode: 401, data: Data(), headers: nil)
        }

        // 2. Make request
        do {
            _ = try await service.status()
        } catch {
            XCTAssertEqual(error as? HTTPError, .unacceptableStatusCode(401))
        }
    }
}
