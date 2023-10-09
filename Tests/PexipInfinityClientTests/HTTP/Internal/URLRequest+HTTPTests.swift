//
// Copyright 2022-2023 Pexip AS
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import XCTest
@testable import PexipInfinityClient

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
}
