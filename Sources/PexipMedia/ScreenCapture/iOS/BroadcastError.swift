#if os(iOS)

import Foundation

/// An object that represents the error occured during IPC.
public enum BroadcastError: LocalizedError, CustomStringConvertible, CustomNSError {
    public static let errorDomain = "com.pexip.PexipMedia.BroadcastError"

    case invalidHeader
    case broadcastFinished(error: Error?)

    public var description: String {
        switch self {
        case .invalidHeader:
            return "Invalid broadcast header"
        case .broadcastFinished:
            return "Screen broadcasting finished"
        }
    }

    public var errorDescription: String? {
        description
    }

    public var errorUserInfo: [String: Any] {
        var info: [String: Any] = [NSLocalizedDescriptionKey: description]

        if case .broadcastFinished(let error) = self {
            if let error = error {
                info[NSUnderlyingErrorKey] = error
            }
        }

        return info
    }
}

#endif
