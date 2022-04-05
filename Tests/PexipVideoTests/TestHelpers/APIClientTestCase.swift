import XCTest
@testable import PexipVideo

// swiftlint:disable test_case_accessibility
class APIClientTestCase<T>: XCTestCase {
    let nodeAddress = URL(string: "https://test.example.com")!
    let alias = ConferenceAlias(uri: "conference@example.com")!
    private(set) var tokenProvider: TokenProviderMock!
    private(set) var client: T!

    // MARK: - Setup

    override func setUpWithError() throws {
        try super.setUpWithError()
        let urlSessionConfiguration = URLSessionConfiguration.ephemeral
        urlSessionConfiguration.protocolClasses = [URLProtocolMock.self]
        let urlSession = URLSession(configuration: urlSessionConfiguration)

        tokenProvider = TokenProviderMock()
        let client = InfinityClient(
            node: Node(address: nodeAddress),
            alias: alias,
            urlSession: urlSession,
            tokenProvider: tokenProvider,
            logger: SilentLogger()
        )
        self.client = try XCTUnwrap(client as? T)
    }
}
