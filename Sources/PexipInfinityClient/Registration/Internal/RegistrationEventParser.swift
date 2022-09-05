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
                try decoder.decode(IncomingRegistrationEvent.self, from: data)
            )
        case .incomingCancelled:
            return .incomingCancelled(try decoder.decode(
                IncomingCancelledRegistrationEvent.self,
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
