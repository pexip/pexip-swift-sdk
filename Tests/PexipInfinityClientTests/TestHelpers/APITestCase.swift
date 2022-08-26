import XCTest
@testable import PexipInfinityClient

// swiftlint:disable test_case_accessibility
class APITestCase: XCTestCase {
    private(set) var urlSession: URLSession!
    private(set) var client: HTTPClient!
    private(set) var lastRequest: URLRequest?

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolMock.self]
        urlSession = URLSession(configuration: configuration)
        client = HTTPClient(session: urlSession)
    }

    // MARK: - Test helpers

    func setResponse(
        statusCode: Int,
        data: Data,
        headers: [String: String] = [:]
    ) throws {
        URLProtocolMock.makeResponse = { [weak self] request in
            self?.lastRequest = request
            return .http(
                statusCode: statusCode,
                data: data,
                headers: headers
            )
        }
    }

    func setResponse(statusCode: Int, json: String? = nil) throws {
        let data = try XCTUnwrap((json ?? "").data(using: .utf8))
        try setResponse(
            statusCode: statusCode,
            data: data,
            headers: ["Content-Type": "application/json"]
        )
    }

    func setResponseError(_ error: Error) {
        URLProtocolMock.makeResponse = { [weak self] request in
            self?.lastRequest = request
            return .error(error)
        }
    }

    // swiftlint:disable function_parameter_count
    func testJSONRequest(
        withMethod method: HTTPMethod,
        url: URL,
        token: InfinityToken?,
        body: Data?,
        responseJSON: String?,
        assertHTTPErrors: Bool = true,
        execute: () async throws -> Void
    ) async throws {
        // 1. Success
        try setResponse(statusCode: 200, json: responseJSON)
        try await execute()
        assertRequest(withMethod: method, url: url, token: token, jsonBody: body)

        // 2. HTTP errors
        if assertHTTPErrors {
            for statusCode in [401, 403, 404, 500] {
                try setResponse(statusCode: statusCode)
                do {
                    try await execute()
                    XCTFail("Should fail with error")
                } catch {
                    XCTAssertEqual(error as? HTTPError, .unacceptableStatusCode(statusCode))
                    assertRequest(withMethod: method, url: url, token: token, jsonBody: body)
                }
            }
        }

        // 3. Other errors
        setResponseError(URLError(.unknown))

        do {
            try await execute()
            XCTFail("Should fail with error")
        } catch {
            XCTAssertEqual((error as? URLError)?.code, .unknown)
            assertRequest(withMethod: method, url: url, token: token, jsonBody: body)
        }
    }

    func assertRequest(
        withMethod method: HTTPMethod,
        url: URL,
        token: InfinityToken?,
        jsonBody: Data?
    ) {
        XCTAssertEqual(lastRequest?.url, url)
        XCTAssertEqual(lastRequest?.httpMethod, method.rawValue)

        if jsonBody != nil {
            XCTAssertEqual(
                lastRequest?.value(forHTTPHeaderField: "Content-Type"),
                "application/json"
            )
        }

        assertRequest(withMethod: method, url: url, token: token, data: jsonBody)
    }

    func assertRequest(
        withMethod method: HTTPMethod,
        url: URL,
        token: InfinityToken? = nil,
        data: Data?
    ) {
        XCTAssertEqual(lastRequest?.url, url)
        XCTAssertEqual(lastRequest?.httpMethod, method.rawValue)

        if let data = data {
            XCTAssertNotNil(lastRequest?.httpBody)
            XCTAssertEqual(lastRequest?.httpBody, data)
        } else {
            XCTAssertNil(lastRequest?.httpBody)
        }

        XCTAssertEqual(
            lastRequest?.value(forHTTPHeaderField: "User-Agent"),
            HTTPHeader.defaultUserAgent.value
        )

        if let token = token {
            XCTAssertEqual(
                lastRequest?.value(forHTTPHeaderField: "token"),
                token.value
            )
        }
    }
}
