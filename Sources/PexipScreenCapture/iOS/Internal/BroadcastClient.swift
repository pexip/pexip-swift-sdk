#if os(iOS)

import Foundation
import Combine
import Network
import CoreMedia

/// Inter-process communication client based on AF_UNIX domain sockets
final class BroadcastClient: Publisher {
    typealias Output = Event
    typealias Failure = Never

    enum Event {
        case connect
        case stop(Error?)
    }

    var isConnected: Bool {
        receivedHandshake.value
    }

    private let connection: NWConnection
    private let sender: DataSender
    private let callbackQueue = DispatchQueue(label: "com.pexip.PexipMedia.BroadcastClient")
    private let receivedHandshake = Synchronized(false)
    private let subject = PassthroughSubject<Event, Never>()

    // MARK: - Init

    init(filePath: String) {
        let endpoint = NWEndpoint.unix(path: filePath)
        self.connection = NWConnection(to: endpoint, using: .tcp)
        self.sender = DataSender(connection: connection)
    }

    deinit {
        stop()
    }

    // MARK: - Internal

    @discardableResult
    func start() -> Bool {
        guard !isConnected else {
            return false
        }

        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                Task { [weak self] in
                    await self?.sendHandshake()
                }
            case .waiting(let error), .failed(let error):
                self?.stop(error: error)
            default:
                break
            }
        }
        connection.start(queue: callbackQueue)

        return true
    }

    func stop() {
        guard isConnected && connection.state != .cancelled else {
            return
        }

        connection.cancel()
        connection.stateUpdateHandler = nil
        receivedHandshake.mutate { $0 = false }
    }

    @discardableResult
    func send(message: BroadcastMessage) async -> Bool {
        guard isConnected else {
            return false
        }

        do {
            try await sender.send(data: message.header.encodedData)
            try await sender.send(data: message.body)
            return true
        } catch {
            stop(error: error)
            return false
        }
    }

    func receive<S: Subscriber>(subscriber: S) where S.Failure == Failure,
                                                     S.Input == Output {
        subject.subscribe(subscriber)
    }

    // MARK: - Private

    private func sendHandshake() async {
        guard !receivedHandshake.value else {
            return
        }

        guard let message = UUID().uuidString.data(using: .utf8) else {
            return
        }

        connection.receive { [weak self] data, _, isComplete, error in
            guard let self = self else {
                return
            }

            if let error = error {
                self.stop(error: error)
            } else if isComplete {
                self.stop(error: nil)
            } else if !self.receivedHandshake.value {
                let isConnected = data == message
                self.receivedHandshake.mutate { $0 = isConnected }
                self.subject.send(.connect)
            }
        }

        do {
            try await sender.send(data: message)
        } catch {
            stop(error: error)
        }
    }

    private func stop(error: Error?) {
        stop()
        subject.send(.stop(error))
    }
}

// MARK: - Private types

private actor DataSender {
    private let connection: NWConnection
    private var task: Task<Void, Error>?

    init(connection: NWConnection) {
        self.connection = connection
    }

    deinit {
        task?.cancel()
    }

    func send(data: Data) async throws {
        if let task = task {
            try? await task.value
        }

        task = Task {
            try await withCheckedThrowingContinuation { continuation in
                connection.send(
                    content: data,
                    completion: .contentProcessed { error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume()
                        }
                    }
                )
            }
        }

        try await task!.value
    }
}

#endif
