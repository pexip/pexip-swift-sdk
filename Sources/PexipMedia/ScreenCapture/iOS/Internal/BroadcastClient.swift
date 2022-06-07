#if os(iOS)

import Foundation
import Network
import PexipUtils

// MARK: - BroadcastClientDelegate

protocol BroadcastClientDelegate: AnyObject {
    func broadcastClient(_ client: BroadcastClient, didStopWithError error: Error?)
}

// MARK: - BroadcastClient

/// Inter-process communication client based on AF_UNIX domain sockets
final class BroadcastClient {
    weak var delegate: BroadcastClientDelegate?

    var isConnected: Bool {
        receivedHandshake.value
    }

    private let connection: NWConnection
    private let sender: DataSender
    private let callbackQueue = DispatchQueue(label: "com.pexip.PexipMedia.BroadcastClient")
    private let receivedHandshake = Synchronized(false)

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

    func start() {
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
    }

    func stop() {
        connection.stateUpdateHandler = nil
        connection.cancel()
    }

    func send(message: BroadcastMessage) async {
        guard receivedHandshake.value else {
            return
        }

        do {
            try await sender.send(data: message.header.encodedData)
            try await sender.send(data: message.body)
        } catch {
            stop(error: error)
        }
    }

    // MARK: - Private

    private func sendHandshake() async {
        guard !receivedHandshake.value else {
            return
        }

        guard let message = UUID().uuidString.data(using: .utf8) else {
            return
        }

        connection.receive { [weak self] (data, _, isComplete, error) in
            guard let self = self else {
                return
            }

            if let error = error {
                self.stop(error: error)
            } else if isComplete {
                self.stop(error: nil)
            } else if !self.receivedHandshake.value {
                self.receivedHandshake.mutate { $0 = data == message }
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
        delegate?.broadcastClient(self, didStopWithError: error)
    }
}

// MARK: - Private types

private actor DataSender {
    private let connection: NWConnection
    private var task: Task<Void, Error>?

    init(connection: NWConnection) {
        self.connection = connection
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
    }
}

#endif
