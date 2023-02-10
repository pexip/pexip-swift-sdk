#if os(iOS)

import Foundation

enum BroadcastNotification: String {
    case senderStarted = "com.pexip.PexipScreenCapture.senderStarted"
    case senderPaused = "com.pexip.PexipScreenCapture.senderPaused"
    case senderResumed = "com.pexip.PexipScreenCapture.senderResumed"
    case senderFinished = "com.pexip.PexipScreenCapture.senderFinished"
    case receiverStarted = "com.pexip.PexipScreenCapture.receiverStarted"
    case receiverFinished = "com.pexip.PexipScreenCapture.receiverFinished"
    case presentationStolen = "com.pexip.PexipScreenCapture.presentationStolen"
    case callEnded = "com.pexip.PexipScreenCapture.callEnded"

    var cfNotificationName: CFNotificationName {
        CFNotificationName(rawValue as CFString)
    }
}

#endif
