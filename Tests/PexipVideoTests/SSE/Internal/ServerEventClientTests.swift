import XCTest
@testable import PexipVideo

final class ServerEventClientTests: APIClientTestCase<ServerEventClientProtocol> {
    // swiftlint:disable function_body_length
    func testEventStream() async throws {
        // 1. Prepare
        var createdRequest: URLRequest?
        var receivedEvents = [ServerEvent]()
        let token = Token.randomToken()
        let message = ServerEvent.Disconnect(reason: "Test")
        let messageDataString = String(
            data: try JSONEncoder().encode(message),
            encoding: .utf8
        ) ?? ""
        let string = """
        id: 1
        data:\(messageDataString)
        event: disconnect


        """
        let data = try XCTUnwrap(string.data(using: .utf8))

        // 2. Mock response
        tokenProvider.token = token
        URLProtocolMock.makeResponse = { request in
            createdRequest = request
            return .http(statusCode: 200, data: data, headers: nil)
        }

        // 2. Receive events from the stream
        do {
            for try await event in try await client.eventStream(lastEventId: nil) {
                receivedEvents.append(event)
            }
        } catch let error as URLSession.EventStreamError {
            XCTAssertEqual(error.response?.url, createdRequest?.url)
            XCTAssertEqual(error.response?.statusCode, 200)
            XCTAssertTrue(error.response?.allHeaderFields.isEmpty == true)
            XCTAssertNil(error.dataStreamError)
        }

        // 3. Assert request
        let expectedUrlString = "\(nodeAddress)/api/client/v2/conferences/\(alias.uri)/events"
        XCTAssertEqual(createdRequest?.url, try XCTUnwrap(URL(string: expectedUrlString)))
        XCTAssertEqual(createdRequest?.httpMethod, "GET")
        XCTAssertEqual(
            createdRequest?.value(forHTTPHeaderField: "User-Agent"),
            HTTPHeader.defaultUserAgent.value
        )
        XCTAssertEqual(
            createdRequest?.value(forHTTPHeaderField: "token"),
            token.value
        )

        // 4. Assert response
        XCTAssertEqual(receivedEvents.count, 1)
        XCTAssertEqual(
            receivedEvents.first,
            ServerEvent(
                rawEvent: .init(
                    id: "1",
                    name: "disconnect",
                    data: "\(messageDataString)",
                    retry: nil
                ),
                message: .disconnect(
                    .init(reason: "Test")
                )
            )
        )
    }
}
