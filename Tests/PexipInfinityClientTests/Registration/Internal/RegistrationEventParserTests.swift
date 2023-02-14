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

final class RegistrationEventParserTests: XCTestCase {
    private var parser: RegistrationEventParser!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        parser = RegistrationEventParser()
    }

    // MARK: - Tests

    func testParseEventDataWithoutName() throws {
        let event = HTTPEvent(
            id: nil,
            name: nil,
            data: "",
            retry: nil
        )
        XCTAssertNil(parser.parseEventData(from: event))
    }

    func testParseEventDataWithoutData() throws {
        let event = HTTPEvent(
            id: "1",
            name: "incoming",
            data: nil,
            retry: nil
        )
        XCTAssertNil(parser.parseEventData(from: event))
    }

    func testParseEventDataWithInvalidData() throws {
        let event = HTTPEvent(
            id: "1",
            name: "incoming",
            data: "",
            retry: nil
        )
        XCTAssertNil(parser.parseEventData(from: event))
    }

    func testIncoming() throws {
        let expectedEvent = IncomingCallEvent(
            conferenceAlias: "Alias",
            remoteDisplayName: "Name",
            token: UUID().uuidString
        )
        let httpEvent = try HTTPEvent.stub(for: expectedEvent, name: "incoming")
        let parsedEvent = parser.parseEventData(from: httpEvent)

        switch parsedEvent {
        case .incoming(let event):
            XCTAssertEqual(event, expectedEvent)
        default:
            XCTFail("Unexpected event type")
        }
    }

    func testIncomingCancelled() throws {
        let expectedEvent = IncomingCallCancelledEvent(
            token: UUID().uuidString
        )
        let httpEvent = try HTTPEvent.stub(for: expectedEvent, name: "incoming_cancelled")
        let parsedEvent = parser.parseEventData(from: httpEvent)

        switch parsedEvent {
        case .incomingCancelled(let event):
            XCTAssertEqual(event, expectedEvent)
        default:
            XCTFail("Unexpected event type")
        }
    }

    func testUnknown() throws {
        let httpEvent = try HTTPEvent.stub(
            for: IncomingCallCancelledEvent(token: UUID().uuidString),
            name: "unknown"
        )
        let event = parser.parseEventData(from: httpEvent)
        XCTAssertNil(event)
    }

    func testOptionalStringDebug() {
        XCTAssertEqual(("Test" as String?).debug, "Test")
        XCTAssertEqual(String?.none.debug, "none")
    }
}
