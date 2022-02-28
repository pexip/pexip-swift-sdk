import XCTest
@testable import PexipVideo

final class ConferenceFactoryTests: XCTestCase {
    private var factory: ConferenceFactory!
    private var urlSession: URLSession!
    private let node = Node(address: URL(string: "https://example.com")!)
    private let callConfiguration = CallConfiguration(
        qualityProfile: .medium,
        supportsAudio: true,
        supportsVideo: true,
        useGoogleStunServersAsBackup: true
    )

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        urlSession = URLSession(configuration: .ephemeral)
        factory = ConferenceFactory(
            logger: SilentLogger(),
            urlSession: urlSession
        )
    }

    // MARK: - Tests

    func testNodeResolver() {
        XCTAssertTrue(factory.nodeResolver() is NodeResolver)
    }

    func testTokenRequester() throws {
        let tokenRequester = factory.tokenRequester(
            node: node,
            alias: try XCTUnwrap(ConferenceAlias(uri: "test@example.com"))
        )
        XCTAssertTrue(tokenRequester is InfinityClient)
    }

    func testConference() throws {
        let conference = factory.conference(
            node: node,
            alias: try XCTUnwrap(ConferenceAlias(uri: "test@example.com")),
            token: .randomToken()
        )
        XCTAssertTrue(conference is Conference)
    }

    func testIceServersWithoutStunInToken() {
        let iceServers = factory.iceServers(
            fromToken: .randomToken(stun: []),
            callConfiguration: callConfiguration
        )
        XCTAssertEqual(iceServers, CallConfiguration.googleStunServers)
    }

    func testIceServersWithStunInToken() {
        let token = Token.randomToken(stun: ["stun:stun.l.google.com:19302"])
        let iceServers = factory.iceServers(
            fromToken: token,
            callConfiguration: callConfiguration
        )
        XCTAssertEqual(iceServers, token.iceServers)
    }
}
