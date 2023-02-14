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

final class InfinityEventSourceTests: XCTestCase {
    private let baseURL = URL(string: "https://example.com/api/conference/name/events")!

    // MARK: - Tests

    func testDebugDescription() {
        let eventSource = InfinityEventSource<String>(
            name: "Test",
            stream: { throw URLError(.badURL) }
        )
        XCTAssertEqual(eventSource.debugDescription, "Test event source")
        XCTAssertEqual(String(reflecting: eventSource), "Test event source")
    }

    func testEvents() async {
        let inputEvents = ["Event1", "Event2"]
        let output = await events(input: [
            .success(inputEvents[0]),
            .success(inputEvents[1])
        ])

        XCTAssertEqual(output.events, inputEvents)
        XCTAssertTrue(output.errors.isEmpty)
        XCTAssertNil(output.streamError)
    }

    func testEventsWithRetry() async {
        let inputEvents = ["Event1", "Event2", "Event3", "Event4"]
        let error = HTTPEventError(response: nil, dataStreamError: nil)
        let output = await events(input: [
            .success(inputEvents[0]),
            .success(inputEvents[1]),
            .failure(error),
            .failure(error),
            .success(inputEvents[2]),
            .success(inputEvents[3])
        ])

        XCTAssertEqual(output.events, inputEvents)
        XCTAssertEqual(output.errors.count, 2)
        XCTAssertTrue(output.errors.allSatisfy { $0 is HTTPEventError })
        XCTAssertNil(output.streamError)
    }

    func testEventsWithMaxRetries() async {
        let inputEvents = ["Event1", "Event2"]
        let error = HTTPEventError(response: nil, dataStreamError: nil)

        let output = await events(input: [
            .success(inputEvents[0]),
            .success(inputEvents[1]),
            .failure(error),
            .failure(error),
            .failure(error),
            .success("Event3")
        ])

        XCTAssertEqual(output.events, inputEvents)
        XCTAssertEqual(output.errors.count, 3)
        XCTAssertTrue(output.errors.allSatisfy { $0 is HTTPEventError })
        XCTAssertTrue(output.streamError is HTTPEventError)
    }

    func testEventsWith401Error() async {
        let inputEvents = ["Event1", "Event2"]
        let response = HTTPURLResponse(
            url: baseURL,
            statusCode: 401,
            httpVersion: "HTTP/1.1",
            headerFields: [:]
        )
        let error = HTTPEventError(response: response, dataStreamError: nil)
        let output = await events(input: [
            .success(inputEvents[0]),
            .success(inputEvents[1]),
            .failure(error),
            .success("Event3")
        ])

        XCTAssertEqual(output.events, inputEvents)
        XCTAssertEqual(output.errors.count, 1)
        XCTAssertTrue(output.errors.first is HTTPEventError)
        XCTAssertTrue(output.streamError is HTTPEventError)
    }

    func testEventsWith403Error() async {
        let inputEvents = ["Event1", "Event2"]
        let response = HTTPURLResponse(
            url: baseURL,
            statusCode: 403,
            httpVersion: "HTTP/1.1",
            headerFields: [:]
        )
        let error = HTTPEventError(response: response, dataStreamError: nil)
        let output = await events(input: [
            .success(inputEvents[0]),
            .success(inputEvents[1]),
            .failure(error),
            .success("Event3")
        ])

        XCTAssertEqual(output.events, inputEvents)
        XCTAssertEqual(output.errors.count, 1)
        XCTAssertTrue(output.errors.first is HTTPEventError)
        XCTAssertTrue(output.streamError is HTTPEventError)
    }

    func testEventsWithUnknownError() async {
        let inputEvents = ["Event1", "Event2"]
        let error = URLError(.badURL)
        let output = await events(input: [
            .success(inputEvents[0]),
            .success(inputEvents[1]),
            .failure(error),
            .success("Event3")
        ])

        XCTAssertEqual(output.events, inputEvents)
        XCTAssertEqual(output.errors.count, 1)
        XCTAssertEqual(output.errors.first as? URLError, error)
        XCTAssertEqual(output.streamError as? URLError, error)
    }

    // MARK: - Private

    private func events(
        input: [Result<String, Error>]
    ) async -> StreamOutput {
        let inputCount = input.count
        var input = input
        var output = StreamOutput(events: [], errors: [])

        let eventSource = InfinityEventSource<String>(
            name: "Test",
            minDelay: 0.1,
            maxDelay: 0.5,
            maxRetryCount: 2,
            stream: {
                AsyncThrowingStream { continuation in
                    do {
                        for _ in 0..<input.count {
                            continuation.yield(try input.removeFirst().get())
                        }
                    } catch {
                        output.errors.append(error)
                        continuation.finish(throwing: error)
                    }
                }
            }
        )

        do {
            for try await event in eventSource.events() {
                output.events.append(event)
                if output.events.count + output.errors.count == inputCount {
                    break
                }
            }
        } catch {
            output.streamError = error
        }

        return output
    }
}

// MARK: - Private types

private struct StreamOutput {
    var events: [String]
    var errors: [Error]
    var streamError: Error?
}
