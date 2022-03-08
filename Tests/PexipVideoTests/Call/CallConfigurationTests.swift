import XCTest
@testable import PexipVideo

final class CallConfigurationTests: XCTestCase {
    func testInit() {
        let mediaFeatures = MediaFeature.all
        let configuration = CallConfiguration(
            qualityProfile: .medium,
            mediaFeatures: mediaFeatures,
            useGoogleStunServersAsBackup: true
        )

        XCTAssertEqual(configuration.qualityProfile, .medium)
        XCTAssertEqual(configuration.mediaFeatures, mediaFeatures)
        XCTAssertTrue(configuration.useGoogleStunServersAsBackup)
    }

    func testBackupIceServers() {
        var configuration = CallConfiguration(
            qualityProfile: .medium,
            mediaFeatures: [.receiveVideo, .receiveAudio],
            useGoogleStunServersAsBackup: true
        )
        XCTAssertFalse(configuration.backupIceServers.isEmpty)

        configuration.useGoogleStunServersAsBackup = false
        XCTAssertTrue(configuration.backupIceServers.isEmpty)
    }
}
