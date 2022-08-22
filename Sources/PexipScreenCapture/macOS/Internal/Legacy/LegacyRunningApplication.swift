#if os(macOS)

import AppKit

struct LegacyRunningApplication: RunningApplication, Hashable {
    let processID: pid_t
    let bundleIdentifier: String
    let applicationName: String
}

// MARK: - Init

extension LegacyRunningApplication {
    init?(info: [CFString: Any], workspace: NSWorkspace = .shared) {
        guard let processID = info[kCGWindowOwnerPID] as? Int else {
            return nil
        }
        self.processID = pid_t(processID)

        guard let bundleIdentifier = workspace.runningApplications.first(where: {
            $0.processIdentifier == processID
        })?.bundleIdentifier else {
            return nil
        }
        self.bundleIdentifier = bundleIdentifier

        guard let name = info[kCGWindowOwnerName] as? String else {
            return nil
        }
        self.applicationName = name
    }
}

#endif
