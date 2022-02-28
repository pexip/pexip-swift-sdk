public protocol TokenRequesterProtocol {
    /**
     Requests a new token from the Pexip Conferencing Node.

     - Parameter request: An object with token request parameters
     - Returns: Information about the service you are connecting to
     - Throws: `TokenError` if "403 Forbidden" is returned. See `TokenError` for more details.
     - Throws: `HTTPError` if a network error was encountered during operation
     */
    func requestToken(with tokenRequest: TokenRequest) async throws -> Token
}
