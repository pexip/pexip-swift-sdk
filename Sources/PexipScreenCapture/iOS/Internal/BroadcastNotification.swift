#if os(iOS)

import Foundation

enum BroadcastNotification: String {
    case broadcastStarted = "com.pexip.PexipMedia.broadcastStarted"
    case broadcastPaused = "com.pexip.PexipMedia.broadcastPaused"
    case broadcastResumed = "com.pexip.PexipMedia.broadcastResumed"
    case broadcastFinished = "com.pexip.PexipMedia.broadcastFinished"
    case serverStarted = "com.pexip.PexipMedia.serverStarted"

    var cfNotificationName: CFNotificationName {
        CFNotificationName(rawValue as CFString)
    }
}

#endif
