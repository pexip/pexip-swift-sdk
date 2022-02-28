import XCTest
@testable import PexipVideo

final class URLRequestHTTPTests: XCTestCase {
    private var url = URL(string: "https://test.example.com")!

    // MARK: - Tests

    func testInit() {
        let request = URLRequest(url: url, httpMethod: .POST)
        XCTAssertEqual(request.url, url)
        XCTAssertEqual(request.httpMethod, "POST")
    }

    func testSetHTTPHeader() {
        var request = URLRequest(url: url, httpMethod: .POST)
        request.setHTTPHeader(.contentType("application/json"))
        XCTAssertEqual(
            request.value(forHTTPHeaderField: "Content-Type"),
            "application/json"
        )
    }

    func testValueForHTTPHeaderName() {
        var request = URLRequest(url: url, httpMethod: .POST)
        request.setHTTPHeader(.contentType("application/json"))
        XCTAssertEqual(
            request.value(forHTTPHeaderName: .contentType),
            "application/json"
        )
    }

    func testSetQueryItems() {
        var request = URLRequest(url: url, httpMethod: .POST)
        request.setQueryItems([URLQueryItem(name: "name", value: "value")])
        XCTAssertEqual(request.url?.query, "name=value")
    }

    func testSetQueryItemsWithNoURL() {
        var request = URLRequest(url: url, httpMethod: .POST)
        request.url = nil
        request.setQueryItems([URLQueryItem(name: "name", value: "value")])
        XCTAssertNil(request.url?.query)
    }

    func testSetQueryItemsWithNoItems() {
        var request = URLRequest(url: url, httpMethod: .POST)
        request.setQueryItems([])
        XCTAssertNil(request.url?.query)
    }

    func testSetJSONBody() throws {
        var request = URLRequest(url: url, httpMethod: .POST)
        let parameters = ["key": "value"]
        try request.setJSONBody(parameters)

        XCTAssertEqual(
            request.value(forHTTPHeaderName: .contentType),
            "application/json"
        )
        XCTAssertEqual(
            try JSONDecoder().decode(
                [String: String].self,
                from: try XCTUnwrap(request.httpBody)
            ),
            parameters
        )
    }

    func testMethodWithDescription() {
        var request = URLRequest(url: url, httpMethod: .POST)
        XCTAssertEqual(
            request.methodWithDescription,
            "POST \(request.description)"
        )

        // No HTTP method
        request.httpMethod = nil
        XCTAssertEqual(
            request.methodWithDescription,
            "GET \(request.description)"
        )
    }
}
