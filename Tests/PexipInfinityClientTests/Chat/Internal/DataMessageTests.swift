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

final class DataMessageTests: XCTestCase {
    private let senderName = "Test"
    private let senderId = UUID().uuidString
    private let bodyType = "text/plain"
    private let payload = "Text message"

    // MARK: - Tests

    func testDecoding() throws {
        let json = """
        {
            "type": "message",
            "body": {
                "origin": "\(senderName)",
                "uuid": "\(senderId)",
                "type": "\(bodyType)",
                "payload": "\(payload)"
            }
        }
        """

        let data = try XCTUnwrap(json.data(using: .utf8))
        let dataMessage = try JSONDecoder().decode(
            DataMessage.self,
            from: data
        )

        switch dataMessage {
        case .text(let message):
            XCTAssertEqual(message.senderName, senderName)
            XCTAssertEqual(message.senderId, senderId)
            XCTAssertEqual(message.type, bodyType)
            XCTAssertEqual(message.payload, payload)
        }
    }

    func testEncoding() throws {
        let message = ChatMessage(
            senderName: senderName,
            senderId: senderId,
            type: bodyType,
            payload: payload
        )
        let dataMessage = DataMessage.text(message)
        let data = try JSONEncoder().encode(dataMessage)
        let decodedDataMessage = try JSONDecoder().decode(
            DataMessage.self,
            from: data
        )

        switch decodedDataMessage {
        case .text(let decodedMessage):
            XCTAssertEqual(decodedMessage.senderName, message.senderName)
            XCTAssertEqual(decodedMessage.senderId, message.senderId)
            XCTAssertEqual(decodedMessage.type, message.type)
            XCTAssertEqual(decodedMessage.payload, message.payload)
        }
    }
}
