import Foundation

public struct HTTPEventError: Error {
    public let response: HTTPURLResponse?
    public let dataStreamError: Error?

    public init(response: HTTPURLResponse?, dataStreamError: Error?) {
        self.response = response
        self.dataStreamError = dataStreamError
    }
}
