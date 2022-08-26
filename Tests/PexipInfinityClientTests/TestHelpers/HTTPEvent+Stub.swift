import Foundation
@testable import PexipInfinityClient

extension HTTPEvent {
    static func stub<T: Encodable>(
        for event: T,
        name: String
    ) throws -> HTTPEvent {
        return HTTPEvent(
            id: "1",
            name: name,
            data: String(
                data: try JSONEncoder().encode(event),
                encoding: .utf8
            ) ?? "",
            retry: nil
        )
    }
}
