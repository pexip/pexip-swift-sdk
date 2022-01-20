import XCTest
@testable import Infinity

final class APIConfigurationTests: XCTestCase {
    func testURLForRequest() throws {
        let uri = try XCTUnwrap(ConferenceURI(rawValue: "test@example.com"))
        let nodeAddress = try XCTUnwrap(URL(string: "https://px01.vc.example.com"))
        let configuration = APIConfiguration(uri: uri, nodeAddress: nodeAddress)
        
        XCTAssertEqual(
            configuration.url(forRequest: "request_token"),
            URL(string: "https://px01.vc.example.com/api/client/v2/conferences/test/request_token")
        )
    }
}
