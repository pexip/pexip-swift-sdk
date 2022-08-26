import Foundation

// MARK: - Protocol

protocol InfinityEventParser {
    associatedtype OutputEvent: Hashable
    func parseEventData(from event: HTTPEvent) -> OutputEvent?
}

// MARK: - Internal extensions

extension JSONDecoder {
    func decode<T>(_ type: T.Type, from data: Data?) throws -> T where T: Decodable {
        guard let data = data else {
            throw HTTPError.noDataInResponse
        }
        return try decode(type, from: data)
    }
}
