import XCTest
import AVFoundation
@testable import PexipMedia

final class MediaCapturePermissionTests: XCTestCase {
    private var permission: MediaCapturePermission!
    private var settingsOpener: SettingsOpenerMock!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        CaptureDevice.status = .notDetermined
        settingsOpener = SettingsOpenerMock()
        permission = MediaCapturePermission(
            mediaType: .video,
            captureDeviceType: CaptureDevice.self,
            settingsOpener: settingsOpener
        )
    }

    // MARK: - Tests

    func testAudio() {
        XCTAssertEqual(MediaCapturePermission.video.mediaType, .video)
    }

    func testVideo() {
        XCTAssertEqual(MediaCapturePermission.audio.mediaType, .audio)
    }

    func testInit() {
        XCTAssertEqual(MediaCapturePermission(mediaType: .video).mediaType, .video)
        XCTAssertEqual(MediaCapturePermission(mediaType: .audio).mediaType, .audio)
    }

    func testAuthorizationStatus() {
        CaptureDevice.status = .denied
        XCTAssertEqual(permission.authorizationStatus, .denied)
    }

    func testIsAuthorized() {
        CaptureDevice.status = .denied
        XCTAssertFalse(permission.isAuthorized)

        CaptureDevice.status = .authorized
        XCTAssertTrue(permission.isAuthorized)
    }

    func testRequestAccessNotDetermined() async {
        CaptureDevice.status = .notDetermined
        let status = await permission.requestAccess()
        XCTAssertEqual(status, .notDetermined)
    }

    func testRequestAccessNotDenied() async {
        CaptureDevice.status = .denied
        let status = await permission.requestAccess()
        XCTAssertEqual(status, .denied)
    }

    func testRequestAccessNotRestricted() async {
        CaptureDevice.status = .restricted
        let status = await permission.requestAccess()
        XCTAssertEqual(status, .restricted)
    }

    func testRequestAccessNotAuthorized() async {
        CaptureDevice.status = .authorized
        let status = await permission.requestAccess()
        XCTAssertEqual(status, .authorized)
    }

    func testRequestAccessUnknown() async throws {
        CaptureDevice.status = try XCTUnwrap(.init(rawValue: 1001))
        let status = await permission.requestAccess()
        XCTAssertEqual(status, CaptureDevice.status)
    }

    func testRequestAccessOpenSettingsIfNeeded() async throws {
        CaptureDevice.status = .denied
        await permission.requestAccess(openSettingsIfNeeded: true)

        XCTAssertEqual(
            settingsOpener.url,
            settingsOpener.openSettingsURL
        )
    }
}

// MARK: - Mocks

private final class CaptureDevice: AVCaptureDevice {
    static var status: AVAuthorizationStatus = .notDetermined

    override class func authorizationStatus(for mediaType: AVMediaType) -> AVAuthorizationStatus {
        return status
    }

    override class func requestAccess(for mediaType: AVMediaType) async -> Bool {
        return status == .authorized
    }
}

private final class SettingsOpenerMock: SettingsOpener {
    private(set) var url: URL?

    var openSettingsURL: URL? {
        URL(string: "settings://test")
    }

    func open(_ url: URL) {
        self.url = url
    }
}
