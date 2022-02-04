import XCTest
import dnssd
@testable import PexipVideo

final class APIConfigurationTests: XCTestCase {
    private var configuration: APIConfiguration!

    // MARK: - Setup

    override func setUpWithError() throws {
        try super.setUpWithError()
        configuration = APIConfiguration(
            nodeAddress: try XCTUnwrap(URL(string: "https://vc.example.com")),
            alias: "test"
        )
    }

    // MARK: - Tests

    func testApiURLForNode() {
        XCTAssertEqual(
            APIConfiguration.apiURL(forNode: configuration.nodeAddress),
            URL(string: "https://vc.example.com/api/client/v2")
        )
    }

    func testApiURL() {
        XCTAssertEqual(
            configuration.apiURL,
            URL(string: "https://vc.example.com/api/client/v2")
        )
    }

    func testConferenceBaseURL() {
        XCTAssertEqual(
            configuration.conferenceBaseURL,
            URL(string: "https://vc.example.com/api/client/v2/conferences/test")
        )
    }

    func testParticipantBaseURL() {
        let participantUUID = UUID()
        let expectedString = "https://vc.example.com/api/client/v2/conferences/test/"
            + "participants/\(participantUUID.uuidString.lowercased())"

        XCTAssertEqual(
            configuration.participantBaseURL(withUUID: participantUUID),
            URL(string: expectedString)
        )
    }

    func testCallBaseURL() {
        let participantUUID = UUID()
        let callUUID = UUID()
        let expectedString = "https://vc.example.com/api/client/v2/conferences/test/"
            + "participants/\(participantUUID.uuidString.lowercased())/"
            + "calls/\(callUUID.uuidString.lowercased())"

        XCTAssertEqual(
            configuration.callBaseURL(participantUUID: participantUUID, callUUID: callUUID),
            URL(string: expectedString)
        )
    }
}
