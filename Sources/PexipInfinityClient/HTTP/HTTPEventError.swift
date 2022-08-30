import Foundation

public struct HTTPEventError: LocalizedError, CustomStringConvertible {
    public let response: HTTPURLResponse?
    public let dataStreamError: Error?
    public var statusCode: Int? {
        response?.statusCode
    }

    // MARK: - Init

    public init(response: HTTPURLResponse?, dataStreamError: Error?) {
        self.response = response
        self.dataStreamError = dataStreamError
    }

    // MARK: - LocalizedError

    public var description: String {
        if let dataStreamError = dataStreamError {
            return "Event source disconnected with error: \(dataStreamError)"
        } else if let statusCode = response?.statusCode {
            return "Event source connection closed, status code: \(statusCode)"
        } else {
            return "Event source connection unexpectedly closed"
        }
    }

    public var errorDescription: String? {
        description
    }
}
