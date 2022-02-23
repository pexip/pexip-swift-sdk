@testable import PexipVideo

final class TokenProviderMock: TokenProvider {
    var token: Token?

    func token() async throws -> Token? {
        token
    }
}
