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

final class URLSessionEventSourceTests: APITestCase {
    private let url = URL(string: "https://test.example.org")!

    // MARK: - Tests

    func testEventSource() async throws {
        // 1. Prepare
        let stream = urlSession.eventSource(
            withRequest: URLRequest(url: url, httpMethod: .GET),
            lastEventId: "11"
        )
        var receivedEvents = [HTTPEvent]()
        let string = """
        : test stream

        data: first event
        id: 1

        data:second event
        event: test
        id: 22
        retry: 2000


        """
        let data = try XCTUnwrap(string.data(using: .utf8))
        try setResponse(statusCode: 200, data: data)

        // 2. Receive events from the stream
        do {
            for try await event in stream {
                receivedEvents.append(event)
            }
        } catch let error as HTTPEventError {
            XCTAssertEqual(error.response?.url, url)
            XCTAssertEqual(error.response?.statusCode, 200)
            XCTAssertTrue(error.response?.allHeaderFields.isEmpty == true)
            XCTAssertNil(error.dataStreamError)
        }

        // 3. Assert
        XCTAssertEqual(
            lastRequest?.value(forHTTPHeaderField: "Last-Event-Id"),
            "11"
        )

        XCTAssertEqual(receivedEvents.count, 2)

        let event1 = receivedEvents[0]
        XCTAssertEqual(event1.id, "1")
        XCTAssertNil(event1.name)
        XCTAssertEqual(event1.data, "first event")
        XCTAssertNil(event1.retry)

        let event2 = receivedEvents[1]
        XCTAssertEqual(event2.id, "22")
        XCTAssertEqual(event2.name, "test")
        XCTAssertEqual(event2.data, "second event")
        XCTAssertEqual(event2.retry, "2000")
    }

    func testEventStreamWithErrors() async throws {
        // 1. Prepare
        let stream = urlSession.eventSource(
            withRequest: URLRequest(url: url, httpMethod: .GET),
            lastEventId: nil
        )
        var receivedEvents = [HTTPEvent]()

        setResponseError(URLError(.badURL))

        // 2. Receive events from the stream
        do {
            for try await event in stream {
                receivedEvents.append(event)
            }
        } catch let error as HTTPEventError {
            XCTAssertNil(error.response)
            XCTAssertEqual((error.dataStreamError as? URLError)?.code, .badURL)
        }

        // 3. Assert
        XCTAssertNil(lastRequest?.value(forHTTPHeaderField: "Last-Event-Id"))
        XCTAssertTrue(receivedEvents.isEmpty)
    }
}
