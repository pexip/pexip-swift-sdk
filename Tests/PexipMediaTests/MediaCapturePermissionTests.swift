//
// Copyright 2022-2024 Pexip AS
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import XCTest
import AVFoundation
#if os(iOS)
import UIKit
#else
import AppKit
#endif
@testable import PexipMedia

final class MediaCapturePermissionTests: XCTestCase {
    private var permission: MediaCapturePermission!
    private var urlOpener: URLOpenerMock!
    #if os(iOS)
    private let settingsURLString = UIApplication.openSettingsURLString
    #endif

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        CaptureDevice.status = .notDetermined
        urlOpener = URLOpenerMock()
        permission = permission(for: .video)
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

    func testRequestAccessOpenAudioSettingsIfNeeded() async throws {
        permission = permission(for: .audio)
        CaptureDevice.status = .denied
        _ = await permission.requestAccess(openSettingsIfNeeded: true)

        #if os(iOS)
        XCTAssertEqual(urlOpener.url?.absoluteString, settingsURLString)
        #else
        XCTAssertEqual(
            urlOpener.url?.absoluteString,
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone"
        )
        #endif
    }

    func testRequestAccessOpenVideoSettingsIfNeeded() async throws {
        permission = permission(for: .video)
        CaptureDevice.status = .denied
        _ = await permission.requestAccess(openSettingsIfNeeded: true)

        #if os(iOS)
        XCTAssertEqual(urlOpener.url?.absoluteString, settingsURLString)
        #else
        XCTAssertEqual(
            urlOpener.url?.absoluteString,
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera"
        )
        #endif
    }

    // MARK: - Helpers

    private func permission(
        for mediaType: MediaCapturePermission.MediaType
    ) -> MediaCapturePermission {
        MediaCapturePermission(
            mediaType: mediaType,
            captureDeviceType: CaptureDevice.self,
            urlOpener: urlOpener
        )
    }
}

// MARK: - Mocks

private final class CaptureDevice: AVCaptureDevice {
    static var status: AVAuthorizationStatus = .notDetermined

    override static func authorizationStatus(for mediaType: AVMediaType) -> AVAuthorizationStatus {
        return status
    }

    override static func requestAccess(for mediaType: AVMediaType) async -> Bool {
        return status == .authorized
    }
}

private final class URLOpenerMock: URLOpener {
    private(set) var url: URL?

    func open(_ url: URL) -> Bool {
        self.url = url
        return true
    }
}
