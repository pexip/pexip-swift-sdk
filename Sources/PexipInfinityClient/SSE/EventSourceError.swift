import Foundation

public struct EventSourceError: Error {
    public let response: HTTPURLResponse?
    public let dataStreamError: Error?

    public init(response: HTTPURLResponse?, dataStreamError: Error?) {
        self.response = response
        self.dataStreamError = dataStreamError
    }
}
