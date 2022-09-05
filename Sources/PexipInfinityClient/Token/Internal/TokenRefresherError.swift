import Foundation

enum TokenRefresherError: LocalizedError, CustomStringConvertible, Hashable {
    case tokenRefreshStarted
    case tokenRefreshEnded

    var description: String {
        switch self {
        case .tokenRefreshStarted:
            return "Token refresh has already started"
        case .tokenRefreshEnded:
            return "Token refresh has already ended"
        }
    }

    var errorDescription: String? {
        description
    }
}
