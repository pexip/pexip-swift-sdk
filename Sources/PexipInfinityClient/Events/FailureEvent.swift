import Foundation

public struct FailureEvent: Hashable {
    public let id: UUID
    public private(set) var receivedAt = Date()
    public let error: Error

    // MARK: - Init

    public init(
        id: UUID = UUID(),
        receivedAt: Date = .init(),
        error: Error
    ) {
        self.id = id
        self.receivedAt = receivedAt
        self.error = error
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(receivedAt)
        hasher.combine(error.localizedDescription)
    }

    // MARK: - Equatable

    public static func == (lhs: FailureEvent, rhs: FailureEvent) -> Bool {
        lhs.id == rhs.id
            && lhs.receivedAt == rhs.receivedAt
            && lhs.error.localizedDescription == rhs.error.localizedDescription
    }
}
