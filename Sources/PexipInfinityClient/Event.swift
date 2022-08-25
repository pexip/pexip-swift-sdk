import Foundation

public struct Event<T: Hashable>: Hashable {
    public let id: String?
    public let name: String?
    public let reconnectionTime: TimeInterval?
    public let data: T
}
