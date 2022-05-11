import AVFoundation

#if os(iOS)
import UIKit
#else
import AppKit
#endif

// MARK: - Protocols

protocol URLOpener {
    func open(_ url: URL) -> Bool
}

#if os(iOS)
extension UIApplication: URLOpener {
    func open(_ url: URL) -> Bool {
        open(url, options: [:], completionHandler: nil)
        return true
    }
}
#else
extension NSWorkspace: URLOpener {}
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
    private let urlOpener: URLOpener

    // MARK: - Init

    init(
        mediaType: MediaType,
        captureDeviceType: AVCaptureDevice.Type = AVCaptureDevice.self,
        urlOpener: URLOpener = {
            #if os(iOS)
            UIApplication.shared
            #else
            NSWorkspace.shared
            #endif
        }()
    ) {
        switch mediaType {
        case .audio:
            self.mediaType = .audio
        case .video:
            self.mediaType = .video
        }

        self.captureDevice = captureDeviceType
        self.urlOpener = urlOpener
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
    public func requestAccess(
        openSettingsIfNeeded: Bool = false
    ) async -> AVAuthorizationStatus {
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
        #if os(iOS)
        let url = URL(string: UIApplication.openSettingsURLString)
        #else
        let setting = mediaType == .video ? "Privacy_Camera" : "Privacy_Microphone"
        let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?\(setting)"
        )
        #endif

        if let url = url {
            _ = urlOpener.open(url)
        }
    }
}
