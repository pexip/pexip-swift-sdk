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

enum DataMessage: Codable {
    case text(ChatMessage)

    private enum CodingKeys: String, CodingKey {
        case type
        case body
    }

    private enum MessageType: String, Codable {
        case text = "message"
    }

    // MARK: - Codable

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(MessageType.self, forKey: .type)

        switch type {
        case .text:
            self = .text(try container.decode(ChatMessage.self, forKey: .body))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .text(let chatMessage):
            try container.encode(MessageType.text, forKey: .type)
            try container.encode(chatMessage, forKey: .body)
        }
    }
}
