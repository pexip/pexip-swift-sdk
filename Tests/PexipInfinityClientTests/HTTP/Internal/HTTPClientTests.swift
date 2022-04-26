import XCTest
@testable import PexipInfinityClient

final class HTTPClientTests: XCTestCase {
    private let url = URL(string: "https://test.example.com")!
    private var request: URLRequest!
    private var client: HTTPClient!

    // MARK: - Setup

    override func setUpWithError() throws {
        try super.setUpWithError()

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolMock.self]

        request = URLRequest(url: url, httpMethod: .POST)
        client = HTTPClient(session: URLSession(configuration: configuration))
    }

    // MARK: - Tests

    func testDataRequest() async throws {
        let expectedData = try XCTUnwrap("String".data(using: .utf8))

        URLProtocolMock.makeResponse = { _ in
            .http(statusCode: 200, data: expectedData, headers: nil)
        }

        let (data, response) = try await client.data(for: request, validate: true)

        XCTAssertEqual(data, expectedData)
        XCTAssertEqual(response.statusCode, 200)
        XCTAssertTrue(response.allHeaderFields.isEmpty)
    }

    func testDataRequestWithError() async throws {
        URLProtocolMock.makeResponse = { _ in .error(URLError(.badURL)) }

        do {
            _ = try await client.data(for: request, validate: true)
            XCTFail("Should fail with error")
        } catch {
            XCTAssertEqual((error as? URLError)?.code, .badURL)
        }
    }

    func testDataRequestWithValidation() async throws {
        URLProtocolMock.makeResponse = { _ in
            .http(statusCode: 401, data: Data(), headers: nil)
        }

        do {
            _ = try await client.data(for: request, validate: true)
            XCTFail("Should fail with error")
        } catch {
            XCTAssertEqual(error as? HTTPError, .unacceptableStatusCode(401))
        }
    }

    func testDataRequestWithoutValidation() async throws {
        let expectedData = try XCTUnwrap("String".data(using: .utf8))

        URLProtocolMock.makeResponse = { _ in
            .http(statusCode: 401, data: expectedData, headers: nil)
        }

        let (data, _) = try await client.data(for: request, validate: false)

        XCTAssertEqual(data, expectedData)
    }

    func testDataRequestWithInvalidHTTPResponse() async throws {
        URLProtocolMock.makeResponse = { _ in .url(Data()) }

        do {
            _ = try await client.data(for: request, validate: true)
            XCTFail("Should fail with error")
        } catch {
            XCTAssertEqual(error as? HTTPError, .invalidHTTPResponse)
        }
    }

    func testJson() async throws {
        let expectedObject = ["result": "value"]
        let data = try JSONEncoder().encode(expectedObject)

        URLProtocolMock.makeResponse = { _ in
            .http(statusCode: 200, data: data, headers: nil)
        }

        let object: String = try await client.json(
            for: request,
            validate: true
        )

        XCTAssertEqual(object, "value")
    }

    func testJsonWithDecodingError() async throws {
        URLProtocolMock.makeResponse = { _ in
            .http(statusCode: 200, data: Data(), headers: nil)
        }

        do {
            _ = try await client.json(
                for: request,
                validate: true
            ) as [String: String]
            XCTFail("Should fail with error")
        } catch {
            XCTAssertTrue(error is DecodingError)
        }
    }
}
