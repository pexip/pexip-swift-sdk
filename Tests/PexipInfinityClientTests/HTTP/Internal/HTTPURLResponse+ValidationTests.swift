//
// Copyright 2022 Pexip AS
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

final class HTTPURLResponseValidationTests: XCTestCase {
    private var url: URL!
    private var request: URLRequest!

    // MARK: - Setup

    override func setUpWithError() throws {
        try super.setUpWithError()
        url = try XCTUnwrap(URL(string: "https://test.example.com"))
        request = URLRequest(url: url, httpMethod: .GET)
        request.setHTTPHeader(.contentType("application/json"))
    }

    // MARK: - Validate

    func testValidateWhenValid() throws {
        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )
        XCTAssertNoThrow(try response?.validate(for: request))
    }

    func testValidateWithInvalidStatusCode() throws {
        let response = HTTPURLResponse(
            url: url,
            statusCode: 404,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )
        XCTAssertThrowsError(try response?.validate(for: request)) { error in
            XCTAssertEqual(error as? HTTPError, .unacceptableStatusCode(404))
        }
    }

    func testValidateWithInvalidContentType() throws {
        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "text/plain"]
        )
        XCTAssertThrowsError(try response?.validate(for: request)) { error in
            XCTAssertEqual(error as? HTTPError, .unacceptableContentType("text/plain"))
        }
    }

    // MARK: - Status code

    func testValidateStatusCodeWhenValid() throws {
        for statusCode in 200..<300 {
            let response = HTTPURLResponse(
                url: url,
                statusCode: statusCode,
                httpVersion: "HTTP/1.1",
                headerFields: nil
            )
            XCTAssertNoThrow(try response?.validateStatusCode())
        }
    }

    func testValidateStatusCodeWhenInvalid() throws {
        let response = HTTPURLResponse(
            url: url,
            statusCode: 401,
            httpVersion: "HTTP/1.1",
            headerFields: nil
        )
        XCTAssertThrowsError(try response?.validateStatusCode()) { error in
            XCTAssertEqual(error as? HTTPError, .unacceptableStatusCode(401))
        }
    }

    // MARK: - Content type

    func testValidateContentTypeWhenValid() throws {
        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "text/plain"]
        )
        XCTAssertNoThrow(try response?.validateContentType(["text/plain"]))
    }

    func testValidateContentTypeWhenInvalid() throws {
        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "text/plain"]
        )
        XCTAssertThrowsError(try response?.validateContentType(["application/json"])) { error in
            XCTAssertEqual(error as? HTTPError, .unacceptableContentType("text/plain"))
        }
    }

    func testValidateContentTypeForRequestWhenValid() throws {
        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )
        XCTAssertNoThrow(try response?.validateContentType(for: request))
    }

    func testValidateContentTypeForRequestWhenInvalid() throws {
        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "text/plain"]
        )
        XCTAssertThrowsError(try response?.validate(for: request)) { error in
            XCTAssertEqual(error as? HTTPError, .unacceptableContentType("text/plain"))
        }
    }

    func testValidateContentTypeWhenNotSpecified() throws {
        request.setValue(nil, forHTTPHeaderField: "Content-Type")
        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: nil
        )
        XCTAssertNoThrow(try response?.validateContentType(for: request))
    }
}
