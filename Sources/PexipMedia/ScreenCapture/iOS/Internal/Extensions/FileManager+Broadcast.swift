#if os(iOS)

import Foundation

extension FileManager {
    func broadcastSocketPath(appGroup: String) -> String {
        let url = containerURL(
            forSecurityApplicationGroupIdentifier: appGroup
        )
        let suffix = "pex_broadcast_FD"
        return url?.appendingPathComponent(suffix).path ?? suffix
    }
}



#endif
