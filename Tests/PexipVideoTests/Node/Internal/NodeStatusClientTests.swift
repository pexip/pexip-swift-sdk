import XCTest
@testable import PexipVideo

final class NodeStatusClientTests: XCTestCase {
    private let nodeAddress = URL(string: "https://test.example.com")!
    private var client: NodeStatusClient!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        let urlSessionConfiguration = URLSessionConfiguration.ephemeral
        urlSessionConfiguration.protocolClasses = [URLProtocolMock.self]
        let urlSession = URLSession(configuration: urlSessionConfiguration)
        client = NodeStatusClient(urlSession: urlSession, logger: .stub)
    }

    // MARK: - Tests

    func testIsInMaintenanceModeTrue() async throws {
        var createdRequest: URLRequest?

        // 1. Mock response
        URLProtocolMock.makeResponse = { request in
            createdRequest = request
            return .http(statusCode: 503, data: Data(), headers: nil)
        }

        // 2. Make request
        let result = try await client.isInMaintenanceMode(nodeAddress: nodeAddress)

        // 3. Assert request
        var expectedRequest = URLRequest(url: nodeAddress, httpMethod: .GET)
        expectedRequest.setHTTPHeader(.defaultUserAgent)
        XCTAssertEqual(createdRequest, expectedRequest)

        // 4. Assert result
        XCTAssertTrue(result)
    }

    func testIsInMaintenanceModeFalse() async throws {
        // 1. Mock response
        URLProtocolMock.makeResponse = { _ in
            .http(statusCode: 200, data: Data(), headers: nil)
        }

        // 2. Make request
        let result = try await client.isInMaintenanceMode(nodeAddress: nodeAddress)

        // 3. Assert result
        XCTAssertFalse(result)
    }

    func testIsInMaintenanceMode404() async throws {
        // 1. Mock response
        URLProtocolMock.makeResponse = { _ in
            .http(statusCode: 404, data: Data(), headers: nil)
        }

        // 2. Make request
        do {
            _ = try await client.isInMaintenanceMode(nodeAddress: nodeAddress)
        } catch {
            XCTAssertEqual(error as? HTTPError, .resourceNotFound("Node"))
        }
    }

    func testIsInMaintenanceModeUnacceptableStatusCode() async throws {
        // 1. Mock response
        URLProtocolMock.makeResponse = { _ in
            .http(statusCode: 401, data: Data(), headers: nil)
        }

        // 2. Make request
        do {
            _ = try await client.isInMaintenanceMode(nodeAddress: nodeAddress)
        } catch {
            XCTAssertEqual(error as? HTTPError, .unacceptableStatusCode(401))
        }
    }
}
