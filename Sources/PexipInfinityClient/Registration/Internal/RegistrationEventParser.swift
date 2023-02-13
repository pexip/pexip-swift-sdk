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

import Foundation
import PexipCore

struct RegistrationEventParser: InfinityEventParser {
    var decoder = JSONDecoder()
    var logger: Logger?

    func parseEventData(from event: HTTPEvent) -> RegistrationEvent? {
        logger?.debug(
            "Got registration event with ID: \(event.id.debug), name: \(event.name.debug)"
        )

        guard let nameString = event.name else {
            logger?.debug("Received registration event without a name")
            return nil
        }

        guard let name = RegistrationEvent.Name(rawValue: nameString) else {
            logger?.debug("Registration event: '\(nameString)' was not handled")
            return nil
        }

        let data = event.data?.data(using: .utf8)

        do {
            return try registrationEvent(withName: name, data: data)
        } catch {
            logger?.error("Failed to decode registration event: '\(name)', error: \(error)")
            return nil
        }
    }

    private func registrationEvent(
        withName name: RegistrationEvent.Name,
        data: Data?
    ) throws -> RegistrationEvent {
        switch name {
        case .incoming:
            return .incoming(
                try decoder.decode(IncomingCallEvent.self, from: data)
            )
        case .incomingCancelled:
            return .incomingCancelled(try decoder.decode(
                IncomingCallCancelledEvent.self,
                from: data
            ))
        }
    }
}

// MARK: - Private extensions

extension Optional where Wrapped == String {
    var debug: String {
        switch self {
        case .none:
            return "none"
        case .some(let wrapped):
            return wrapped
        }
    }
}
