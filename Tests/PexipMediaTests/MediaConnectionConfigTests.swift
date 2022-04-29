import XCTest
@testable import PexipMedia

final class MediaConnectionConfigTests: XCTestCase {
    func testInit() {
        let iceServer = IceServer(urls: [
            "stun:stun.l.google.com:19302",
            "stun:stun1.l.google.com:19302"
        ])
        let config = MediaConnectionConfig(
            iceServers: [iceServer],
            presentationInMain: true,
            mainQualityProfile: .high
        )

        XCTAssertEqual(config.iceServers, [iceServer])
        XCTAssertTrue(config.presentationInMain)
        XCTAssertEqual(config.mainQualityProfile, .high)
    }

    func testInitWithDefaults() {
        let config = MediaConnectionConfig()

        XCTAssertEqual(config.iceServers, [MediaConnectionConfig.googleIceServer])
        XCTAssertFalse(config.presentationInMain)
        XCTAssertEqual(config.mainQualityProfile, .medium)
    }
}
