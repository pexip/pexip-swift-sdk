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
import Combine
@testable import PexipInfinityClient

final class ChatMessageTests: XCTestCase {
    private let senderName = "Test"
    private let senderId = UUID().uuidString
    private let payload = "Text message"

    // MARK: - Tests

    func testInit() throws {
        let bodyType = "text/plain"
        let message = ChatMessage(
            senderName: senderName,
            senderId: senderId,
            type: bodyType,
            payload: payload
        )

        XCTAssertEqual(message.senderName, senderName)
        XCTAssertEqual(message.senderId, senderId)
        XCTAssertEqual(message.type, bodyType)
        XCTAssertEqual(message.payload, payload)
    }

    func testInitWithDefaultType() throws {
        let message = ChatMessage(
            senderName: senderName,
            senderId: senderId,
            payload: payload
        )

        XCTAssertEqual(message.senderName, senderName)
        XCTAssertEqual(message.type, "text/plain")
    }
}
