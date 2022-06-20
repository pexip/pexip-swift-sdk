#if os(macOS)

import CoreGraphics
#if canImport(ScreenCaptureKit)
import ScreenCaptureKit
#endif

/// An object that retrieves the displays and windows for screen capture.
public protocol ScreenVideoSourceEnumerator {
    /// The url to the app's privacy settings.
    var permissionSettingsURL: URL? { get }

    /// Retrieves the displays for screen capture.
    func getShareableDisplays() async throws -> [Display]

    /// Retrieves the windows for screen capture.
    func getShareableWindows() async throws -> [Window]

    /// Retrieves all on screen windows, excluding desktop windows.
    func getAllOnScreenWindows() async throws -> [Window]
}

// MARK: - Default implementation

public extension ScreenVideoSourceEnumerator {
    var permissionSettingsURL: URL? {
        let prefix = "x-apple.systempreferences:com.apple.preference.security"
        let setting = "Privacy_ScreenRecording"
        return URL(string: "\(prefix)?\(setting)")
    }

    func getShareableWindows() async throws -> [Window] {
        try await getAllOnScreenWindows().filter {
            $0.windowLayer == 0
                && $0.title != nil
                && $0.title != ""
                && $0.application != nil
                && $0.application?.bundleIdentifier != Bundle.main.bundleIdentifier
        }
    }
}

#endif
