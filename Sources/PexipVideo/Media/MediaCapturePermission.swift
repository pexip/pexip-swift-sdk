import AVFoundation
#if os(iOS)
import UIKit
#endif

// MARK: - Protocols

protocol SettingsOpener {
    static var openSettingsURLString: String { get }

    func open(
        _ url: URL,
        options: [UIApplication.OpenExternalURLOptionsKey: Any],
        completionHandler completion: ((Bool) -> Void)?
    )
}

#if os(iOS)
extension UIApplication: SettingsOpener {}
#endif

// MARK: - Implementation

public struct MediaCapturePermission {
    /// The media type, either video or audio
    public enum MediaType {
        case audio
        case video
    }

    public enum Status {
        case granted
        case requested
    }

    public static let audio = MediaCapturePermission(mediaType: .audio)
    public static let video = MediaCapturePermission(mediaType: .video)

    let mediaType: AVMediaType
    private let captureDevice: AVCaptureDevice.Type
    private let settingsOpener: SettingsOpener

    // MARK: - Init

    #if os(iOS)
    init(mediaType: MediaType) {
        self.init(
            mediaType: mediaType,
            settingsOpener: UIApplication.shared
        )
    }
    #endif

    init(
        mediaType: MediaType,
        captureDeviceType: AVCaptureDevice.Type = AVCaptureDevice.self,
        settingsOpener: SettingsOpener
    ) {
        switch mediaType {
        case .audio:
            self.mediaType = .audio
        case .video:
            self.mediaType = .video
        }

        self.captureDevice = captureDeviceType
        self.settingsOpener = settingsOpener
    }

    // MARK: - Public

    /// Authorization status for accessing the hardware supporting the media type.
    public var authorizationStatus: AVAuthorizationStatus {
        captureDevice.authorizationStatus(for: mediaType)
    }

    /// If the client is authorized to access the hardware supporting the media type.
    public var isAuthorized: Bool {
        authorizationStatus == .authorized
    }

    @MainActor
    @discardableResult
    public func requestAccess(openSettingsIfNeeded: Bool = false) async -> AVAuthorizationStatus {
        switch authorizationStatus {
        case .notDetermined:
            await captureDevice.requestAccess(for: mediaType)
        case .restricted, .denied:
            if openSettingsIfNeeded {
                openSettings()
            }
        case .authorized:
            break
        @unknown default:
            break
        }

        return authorizationStatus
    }

    private func openSettings() {
        if let url = URL(string: type(of: settingsOpener).openSettingsURLString) {
            settingsOpener.open(url, options: [:], completionHandler: nil)
        }
    }
}
