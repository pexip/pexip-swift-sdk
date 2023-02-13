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

final class HTTPEventErrorTests: XCTestCase {
    private let urlError = URLError(.unknown)
    private let response = HTTPURLResponse(
        url: URL(string: "https://example.com")!,
        statusCode: 401, httpVersion: "HTTP/1.1",
        headerFields: [:]
    )!

    // MARK: - Tests

    func testInit() {
        let error = HTTPEventError(response: response, dataStreamError: urlError)

        XCTAssertEqual(error.response, response)
        XCTAssertEqual(error.dataStreamError as? URLError, urlError)
    }

    func testDescription() {
        let errors = [
            HTTPEventError(response: nil, dataStreamError: urlError),
            HTTPEventError(response: response, dataStreamError: nil),
            HTTPEventError(response: nil, dataStreamError: nil)
        ]

        for error in errors {
            XCTAssertEqual(error.description, error.errorDescription)
        }

        XCTAssertTrue(errors[0].description.contains("\(urlError.localizedDescription)"))
        XCTAssertTrue(errors[1].description.contains("\(response.statusCode)"))
        XCTAssertFalse(errors[2].description.isEmpty)
    }
}
