#if os(macOS)

import AppKit
#if canImport(ScreenCaptureKit)
import ScreenCaptureKit
#endif

/// An object that represents an app running on a device.
public struct RunningApplication: Hashable {
    /// The system process identifier of the app.
    public let processID: pid_t
    /// The unique bundle identifier of the app.
    public let bundleIdentifier: String
    /// The display name of the app.
    public let applicationName: String

    /// Returns the apps icon
    public func loadAppIcon(workspace: NSWorkspace = .shared) -> NSImage? {
        guard let path = workspace.urlForApplication(
            withBundleIdentifier: bundleIdentifier
        )?.path else {
            return nil
        }
        return workspace.icon(forFile: path)
    }

    // MARK: - Init

    /**
     Create a new object that represents an app running on a device.
     - Parameters:
        - processID: The system process identifier of the app.
        - bundleIdentifier: The unique bundle identifier of the app.
        - applicationName: The display name of the app.
     */
    public init(processID: pid_t, bundleIdentifier: String, applicationName: String) {
        self.processID = processID
        self.bundleIdentifier = bundleIdentifier
        self.applicationName = applicationName
    }

    @available(macOS 12.3, *)
    init(scRunningApplication: SCRunningApplication) {
        self.processID = scRunningApplication.processID
        self.bundleIdentifier = scRunningApplication.bundleIdentifier
        self.applicationName = scRunningApplication.bundleIdentifier
    }

    init?(info: [String: Any], workspace: NSWorkspace = .shared) {
        guard let processID = info[kCGWindowOwnerPID as String] as? Int else {
            return nil
        }
        self.processID = pid_t(processID)

        guard let bundleIdentifier = workspace.runningApplications.first(where: {
            $0.processIdentifier == processID
        })?.bundleIdentifier else {
            return nil
        }
        self.bundleIdentifier = bundleIdentifier

        guard let name = info[kCGWindowOwnerName as String] as? String else {
            return nil
        }
        self.applicationName = name
    }
}

#endif
