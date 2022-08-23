import Foundation

public protocol TokenWithExpiration {
    var value: String { get }
    var expires: TimeInterval { get }
    var updatedAt: Date { get }
}

// MARK: - Helper functions

public extension TokenWithExpiration {
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
