import XCTest
@testable import PexipVideo

class URLSessionHTTPTests: XCTestCase {
    private let url = URL(string: "https://test.example.com")!
    private var request: URLRequest!
    private var urlSession: URLSession!

    // MARK: - Setup

    override func setUpWithError() throws {
        try super.setUpWithError()

        request = URLRequest(url: url, httpMethod: .POST)

        let urlSessionConfiguration = URLSessionConfiguration.ephemeral
        urlSessionConfiguration.protocolClasses = [URLProtocolMock.self]
        urlSession = URLSession(configuration: urlSessionConfiguration)
    }

    // MARK: - Tests

    func testDataRequest() async throws {
        let expectedData = try XCTUnwrap("String".data(using: .utf8))

        URLProtocolMock.makeResponse = { _ in
            .http(statusCode: 200, data: expectedData, headers: nil)
        }

        let (data, response) = try await urlSession.data(
            for: request,
            validate: true,
            logger: nil
        )

        XCTAssertEqual(data, expectedData)
        XCTAssertEqual(response.statusCode, 200)
        XCTAssertTrue(response.allHeaderFields.isEmpty)
    }

    func testDataRequestWithError() async throws {
        URLProtocolMock.makeResponse = { _ in .error(URLError(.badURL)) }

        do {
            _ = try await urlSession.data(
                for: request,
                validate: true,
                logger: nil
            )
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
            _ = try await urlSession.data(
                for: request,
                validate: true,
                logger: nil
            )
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

        let (data, _) = try await urlSession.data(
            for: request,
            validate: false,
            logger: nil
        )

        XCTAssertEqual(data, expectedData)
    }

    func testDataRequestWithInvalidHTTPResponse() async throws {
        URLProtocolMock.makeResponse = { _ in .url(Data()) }

        do {
            _ = try await urlSession.data(
                for: request,
                validate: true,
                logger: nil
            )
            XCTFail("Should fail with error")
        } catch {
            XCTAssertEqual(error as? HTTPError, .invalidHTTPResponse)
        }
    }

    func testJson() async throws {
        let expectedObject = ["Key": "Value"]
        let data = try JSONEncoder().encode(expectedObject)

        URLProtocolMock.makeResponse = { _ in
            .http(statusCode: 200, data: data, headers: nil)
        }

        let object: [String: String] = try await urlSession.json(
            for: request,
            validate: true,
            decoder: JSONDecoder(),
            logger: nil
        )

        XCTAssertEqual(object, expectedObject)
    }

    func testJsonWithDecodingError() async throws {
        URLProtocolMock.makeResponse = { _ in
            .http(statusCode: 200, data: Data(), headers: nil)
        }

        do {
            _ = try await urlSession.json(
                for: request,
                validate: true,
                decoder: JSONDecoder(),
                logger: nil
            ) as [String: String]
            XCTFail("Should fail with error")
        } catch {
            XCTAssertTrue(error is DecodingError)
        }
    }
}
