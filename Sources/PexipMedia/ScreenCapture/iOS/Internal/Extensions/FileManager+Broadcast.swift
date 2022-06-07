#if os(iOS)

import Foundation

extension FileManager {
    func broadcastSocketPath(appGroup: String) -> String {
        let url = containerURL(
            forSecurityApplicationGroupIdentifier: appGroup
        )
        return url?.appendingPathComponent("pex_broadcast_FD").path ?? ""
    }
}

#endif
