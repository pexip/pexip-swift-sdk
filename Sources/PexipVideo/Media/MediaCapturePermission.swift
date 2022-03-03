import AVFoundation
#if os(iOS)
import UIKit
#endif

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
    private let openSettings: () -> Void

    // MARK: - Init

    init(
        mediaType: MediaType,
        captureDeviceType: AVCaptureDevice.Type = AVCaptureDevice.self,
        openSettings: @escaping () -> Void = {
            #if os(iOS)
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
            #endif
        }
    ) {
        switch mediaType {
        case .audio:
            self.mediaType = .audio
        case .video:
            self.mediaType = .video
        }

        self.captureDevice = captureDeviceType
        self.openSettings = openSettings
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
}
