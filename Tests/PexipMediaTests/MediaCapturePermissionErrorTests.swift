import XCTest
import AVFoundation
@testable import PexipMedia

final class MediaCapturePermissionErrorTests: XCTestCase {
    func testInitWithStatus() {
        XCTAssertEqual(MediaCapturePermissionError(status: .denied), .denied)
        XCTAssertEqual(MediaCapturePermissionError(status: .restricted), .restricted)
        XCTAssertNil(MediaCapturePermissionError(status: .authorized))
        XCTAssertNil(MediaCapturePermissionError(status: .notDetermined))
        XCTAssertNil(MediaCapturePermissionError(status: .init(rawValue: 1234)!))
    }

    func testDescription() {
        for state in MediaCapturePermissionError.allCases {
            XCTAssertEqual(state.description, state.errorDescription)
        }
    }
}
