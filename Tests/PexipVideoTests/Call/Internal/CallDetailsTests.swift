import XCTest
@testable import PexipVideo

final class CallDetailsTests: XCTestCase {
    func testDecoding() throws {
        let sdp = UUID().uuidString
        let id = UUID()
        let json = """
        {
            "sdp": "\(sdp)",
            "call_uuid": "\(id.uuidString.lowercased())"
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        let callDetails = try JSONDecoder().decode(
            CallDetails.self,
            from: data
        )

        XCTAssertEqual(callDetails, CallDetails(sdp: sdp, id: id))
    }
}
