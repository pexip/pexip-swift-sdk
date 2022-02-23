import XCTest
import dnssd
@testable import PexipVideo

final class InfinityClientTests: XCTestCase {
    private var nodeAddress: URL!
    private var tokenStorage: TokenStorage!
    private var client: InfinityClient!

    // MARK: - Setup

    override func setUpWithError() throws {
        try super.setUpWithError()
        nodeAddress = URL(string: "https://vc.example.com")
        tokenStorage = TokenStorage(token: .randomToken())
        client = InfinityClient(
            nodeAddress: nodeAddress,
            alias: try XCTUnwrap(ConferenceAlias(uri: "test@vc.example.com")),
            urlSession: .shared,
            tokenProvider: tokenStorage,
            logger: SilentLogger()
        )
    }

    // MARK: - Tests

    func testApiURLForNode() {
        XCTAssertEqual(
            InfinityClient.apiURL(forNode: nodeAddress),
            URL(string: "https://vc.example.com/api/client/v2")
        )
    }

    func testRequestWithConferencePathAndTokenFromStorage() async throws {
        let request = try await client.request(
            withMethod: .GET,
            path: .conference,
            name: "request"
        )
        var expectedRequest = URLRequest(
            url: try XCTUnwrap(
                URL(string: "https://vc.example.com/api/client/v2/conferences/test@vc.example.com/request")
            ),
            httpMethod: .GET
        )
        expectedRequest.setHTTPHeader(.defaultUserAgent)
        expectedRequest.setHTTPHeader(
            .init(name: "token", value: try await tokenStorage.token()?.value ?? "")
        )

        XCTAssertEqual(request, expectedRequest)
    }

    func testRequestWithConferencePathAndCustomTokenValue() async throws {
        let customToken = Token.randomToken()
        let request = try await client.request(
            withMethod: .GET,
            path: .conference,
            name: "request",
            token: .value(customToken)
        )
        var expectedRequest = URLRequest(
            url: try XCTUnwrap(
                URL(string: "https://vc.example.com/api/client/v2/conferences/test@vc.example.com/request")
            ),
            httpMethod: .GET
        )
        expectedRequest.setHTTPHeader(.defaultUserAgent)
        expectedRequest.setHTTPHeader(
            .init(name: "token", value: customToken.value)
        )

        XCTAssertEqual(request, expectedRequest)
    }

    func testRequestWithConferencePathAndWithoutToken() async throws {
        let request = try await client.request(
            withMethod: .GET,
            path: .conference,
            name: "request",
            token: .none
        )
        var expectedRequest = URLRequest(
            url: try XCTUnwrap(
                URL(string: "https://vc.example.com/api/client/v2/conferences/test@vc.example.com/request")
            ),
            httpMethod: .GET
        )
        expectedRequest.setHTTPHeader(.defaultUserAgent)

        XCTAssertEqual(request, expectedRequest)
    }

    func testRequestWithParticipantPath() async throws {
        let participantId = UUID()
        let request = try await client.request(
            withMethod: .POST,
            path: .participant(id: participantId),
            name: "request",
            token: .none
        )
        let expectedUrlString = "https://vc.example.com/api/client/v2/conferences/test@vc.example.com/"
            + "participants/\(participantId.uuidString.lowercased())/"
            + "request"
        var expectedRequest = URLRequest(
            url: try XCTUnwrap(URL(string: expectedUrlString)),
            httpMethod: .POST
        )
        expectedRequest.setHTTPHeader(.defaultUserAgent)

        XCTAssertEqual(request, expectedRequest)
    }

    func testRequestWithCallPath() async throws {
        let participantId = UUID()
        let callId = UUID()
        let request = try await client.request(
            withMethod: .POST,
            path: .call(participantId: participantId, callId: callId),
            name: "request",
            token: .none
        )
        let expectedUrlString = "https://vc.example.com/api/client/v2/conferences/test@vc.example.com/"
            + "participants/\(participantId.uuidString.lowercased())/"
            + "calls/\(callId.uuidString.lowercased())/"
            + "request"
        var expectedRequest = URLRequest(
            url: try XCTUnwrap(URL(string: expectedUrlString)),
            httpMethod: .POST
        )
        expectedRequest.setHTTPHeader(.defaultUserAgent)

        XCTAssertEqual(request, expectedRequest)
    }
}
