#if os(macOS)

import AppKit

/// An object that represents an app running on a device.
public protocol RunningApplication {
    /// The system process identifier of the app.
    var processID: pid_t { get }

    /// The unique bundle identifier of the app.
    var bundleIdentifier: String { get }

    /// The display name of the app.
    var applicationName: String { get }
}

// MARK: - Default implementations

public extension RunningApplication {
    func loadAppIcon(workspace: NSWorkspace = .shared) -> NSImage? {
        guard let path = workspace.urlForApplication(
            withBundleIdentifier: bundleIdentifier
        )?.path else {
            return nil
        }
        return workspace.icon(forFile: path)
    }
}

#endif
