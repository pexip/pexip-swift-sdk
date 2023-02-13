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

import Foundation

/// A chat message that has been sent to the conference.
public struct ChatMessage: Codable, Hashable {
    private enum CodingKeys: String, CodingKey {
        case senderName = "origin"
        case senderId = "uuid"
        case type
        case payload
    }

    /// Name of the sending participant.
    public let senderName: String

    /// UUID of the sending participant.
    public let senderId: String

    /// MIME content-type of the message, usually text/plain.
    public let type: String

    /// Message contents.
    public let payload: String

    /// A date when the message was sent or received.
    public private(set) var date = Date()

    @available(*, deprecated, renamed: "date")
    public var receivedAt: Date { date }

    /**
     - Parameters:
        - senderName: Name of the sending participant
        - senderId: UUID of the sending participant
        - type: MIME content-type of the message, usually text/plain
        - payload: Message contents
        - date: A date when the message was sent or received.
     */
    public init(
        senderName: String,
        senderId: String,
        type: String = "text/plain",
        payload: String,
        date: Date = .init()
    ) {
        self.senderName = senderName
        self.senderId = senderId
        self.type = type
        self.payload = payload
        self.date = date
    }
}
