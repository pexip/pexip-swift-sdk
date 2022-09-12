import Foundation

public protocol InfinityToken {
    static var name: String { get }

    var value: String { get }
    var expires: TimeInterval { get }
    var updatedAt: Date { get }
    func updating(
        value: String,
        expires: String,
        updatedAt: Date
    ) -> Self
}

// MARK: - Helper functions

public extension InfinityToken {
    var expiresAt: Date {
        updatedAt.addingTimeInterval(expires)
    }

    var refreshDate: Date {
        let refreshInterval = expires / 2
        return updatedAt.addingTimeInterval(refreshInterval)
    }

    func isExpired(currentDate: Date = .init()) -> Bool {
        currentDate >= expiresAt
    }
}
