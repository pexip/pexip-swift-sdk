import Foundation
import PexipUtils

struct RegistrationEventParser {
    var decoder = JSONDecoder()
    var logger: Logger?

    func registrationEvent(from event: HTTPEvent) -> RegistrationEvent? {
        logger?.debug(
            "Got registration event with ID: \(event.id ?? "?"), name: \(event.name ?? "?")"
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
