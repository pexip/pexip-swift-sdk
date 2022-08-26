import Foundation

public struct Event<T: Hashable>: Hashable {
    public let id: String?
    public let name: String?
    public let reconnectionTime: TimeInterval?
    public let data: T

    // MARK: - Init

    public init(
        id: String? = nil,
        name: String? = nil,
        reconnectionTime: TimeInterval? = nil,
        data: T
    ) {
        self.id = id
        self.name = name
        self.reconnectionTime = reconnectionTime
        self.data = data
    }
}
