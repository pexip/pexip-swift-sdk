import Foundation

public struct FailureEvent: Hashable {
    public let id: UUID
    public let error: Error

    // MARK: - Init

    public init(
        id: UUID = UUID(),
        error: Error
    ) {
        self.id = id
        self.error = error
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(error.localizedDescription)
    }

    // MARK: - Equatable

    public static func == (lhs: FailureEvent, rhs: FailureEvent) -> Bool {
        lhs.id == rhs.id
            && lhs.error.localizedDescription == rhs.error.localizedDescription
    }
}
