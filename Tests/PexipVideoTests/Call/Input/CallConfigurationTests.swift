import XCTest
@testable import PexipVideo

final class CallConfigurationTests: XCTestCase {
    func testInit() {
        let configuration = CallConfiguration(
            qualityProfile: .medium,
            supportsAudio: true,
            supportsVideo: false,
            useGoogleStunServersAsBackup: true
        )

        XCTAssertEqual(configuration.qualityProfile, .medium)
        XCTAssertTrue(configuration.supportsAudio)
        XCTAssertFalse(configuration.supportsVideo)
        XCTAssertTrue(configuration.useGoogleStunServersAsBackup)
    }

    func testBackupIceServers() {
        var configuration = CallConfiguration(
            qualityProfile: .medium,
            supportsAudio: true,
            supportsVideo: false,
            useGoogleStunServersAsBackup: true
        )
        XCTAssertFalse(configuration.backupIceServers.isEmpty)

        configuration.useGoogleStunServersAsBackup = false
        XCTAssertTrue(configuration.backupIceServers.isEmpty)
    }
}
