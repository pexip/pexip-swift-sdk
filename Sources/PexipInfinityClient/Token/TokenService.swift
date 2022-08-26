public protocol TokenService {
    /**
     Refreshes the token to get a new one.

     - Parameter token: Current valid token
     - Returns: New token
     - Throws: `HTTPError` if a network error was encountered during operation
     */
    func refreshToken(_ token: InfinityToken) async throws -> TokenRefreshResponse

    /**
     Releases the token (effectively a disconnect for the participant).

     - Parameter token: Current valid token
     - Throws: `HTTPError` if a network error was encountered during operation
     */
    func releaseToken(_ token: InfinityToken) async throws
}
