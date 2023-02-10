#if os(iOS)

import Foundation

/// An object that represents the error occured during IPC.
@frozen
public enum BroadcastError: LocalizedError, CustomStringConvertible, CustomNSError {
    public static let errorDomain = "com.pexip.PexipScreenCapture.BroadcastError"

    case noConnection
    case callEnded
    case presentationStolen
    case broadcastFinished

    public var description: String {
        switch self {
        case .noConnection:
            return "No connection to the main app. Most likely you're not in a call."
        case .callEnded:
            return "Call ended."
        case .presentationStolen:
            return "Presentation has been stolen by another participant."
        case .broadcastFinished:
            return "Screen broadcast finished."
        }
    }

    public var errorDescription: String? {
        description
    }

    public var errorUserInfo: [String: Any] {
        return [NSLocalizedDescriptionKey: description]
    }
}

#endif
