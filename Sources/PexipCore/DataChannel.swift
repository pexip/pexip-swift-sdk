import Foundation
import Combine

// MARK: - Protocols

public protocol DataSender: AnyObject {
    @discardableResult
    func send(_ data: Data) async throws -> Bool
}

public protocol DataReceiver: AnyObject {
    @discardableResult
    func receive(_ data: Data) async throws -> Bool
}

// MARK: - Data channel

/// The object responsible for sending and receiving arbitrary data messages.
public final class DataChannel {
    /// The id of the data channel.
    public let id: Int32

    /// Sends outgoing data messages,
    /// e.g. via the peer connection's data channel.
    public weak var sender: DataSender?

    /// Receives new icoming data messages,
    /// e.g. from the peer connection's data channel.
    public weak var receiver: DataReceiver?

    /// Creates a new instance of ``DataChannel``
    /// - Parameter id: The id of the data channel.
    public init(id: Int32) {
        self.id = id
    }
}
