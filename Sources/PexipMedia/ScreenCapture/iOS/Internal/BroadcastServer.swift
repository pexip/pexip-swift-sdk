#if os(iOS)

import Foundation
import Network
import PexipUtils

// MARK: - BroadcastServerDelegate

protocol BroadcastServerDelegate: AnyObject {
    func broadcastServerDidStart(_ server: BroadcastServer)
    func broadcastServer(
        _ server: BroadcastServer,
        didReceiveMessage message: BroadcastMessage
    )
    func broadcastServer(_ server: BroadcastServer, didStopWithError error: Error?)
}

// MARK: - BroadcastServer

/// Inter-process communication server based on AF_UNIX domain sockets
final class BroadcastServer {
    weak var delegate: BroadcastServerDelegate?

    private let listener: NWListener
    private let path: String
    private let fileManager: FileManager
    private let receivedHandshake = Synchronized(false)
    private let callbackQueue = DispatchQueue(label: "com.pexip.PexipMedia.BroadcastServer")
    /// Accept only single connection.
    private var connection: NWConnection?

    // MARK: - Init

    init(path: String, fileManager: FileManager = .default) throws {
        let params = NWParameters.tcp
        params.requiredLocalEndpoint = NWEndpoint.unix(path: path)

        self.listener = try NWListener(using: params)
        self.path = path
        self.fileManager = fileManager
    }

    deinit {
        try? stop()
    }

    // MARK: - Internal

    func start() throws {
        do {
            try removeSocketFile()

            listener.stateUpdateHandler = { [weak self] state in
                guard let self = self else {
                    return
                }

                switch state {
                case .ready:
                    self.delegate?.broadcastServerDidStart(self)
                case .failed(let error):
                    self.stop(error: error)
                default:
                    break
                }
            }

            listener.newConnectionHandler = { [weak self] newConnection in
                if self?.connection == nil {
                    // Accept a new connection
                    self?.setupConnection(newConnection)
                } else {
                    // If connection has already been established, reject it.
                    newConnection.cancel()
                }
            }

            listener.start(queue: callbackQueue)
        } catch {
            try stop()
            throw error
        }
    }

    func stop() throws {
        if listener.state != .cancelled {
            listener.cancel()
            listener.stateUpdateHandler = nil
            listener.newConnectionHandler = nil
        }

        if connection != nil {
            connection?.cancel()
            connection?.stateUpdateHandler = nil
            connection = nil
        }

        try removeSocketFile()
    }

    // MARK: - Private

    private func setupConnection(_ connection: NWConnection) {
        self.connection = connection

        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .waiting(let error), .failed(let error):
                self?.stop(error: error)
            case .ready:
                self?.readHandshake()
            default:
                break
            }
        }

        connection.start(queue: callbackQueue)
    }

    private func readHandshake() {
        connection?.receive { [weak self] (data, _, isComplete, error) in
            guard let self = self, data != nil else {
                return
            }

            guard error == nil, !isComplete else {
                self.stop(error: error)
                return
            }

            if !self.receivedHandshake.value {
                self.receivedHandshake.mutate { $0 = true }
                self.connection?.send(content: data, completion: .idempotent)
                self.readHeader()
            }
        }
    }

    private func readHeader() {
        guard receivedHandshake.value else {
            return
        }

        let headerLength = BroadcastHeader.encodedSize

        connection?.receive(
            minimumIncompleteLength: headerLength,
            maximumLength: headerLength,
            completion: { [weak self] (data, _, isComplete, error) in
                guard let self = self else {
                    return
                }

                guard error == nil, !isComplete else {
                    self.stop(error: error)
                    return
                }

                if var data = data, data.count == headerLength {
                    if let header = data.withUnsafeMutableBytes({ buffer in
                        BroadcastHeader(buffer)
                    }) {
                        self.readBody(header: header)
                    } else {
                        self.stop(error: BroadcastError.invalidHeader)
                    }
                }
            }
        )
    }

    private func readBody(header: BroadcastHeader) {
        guard receivedHandshake.value else {
            return
        }

        let bodyLength = Int(header.contentLength)

        connection?.receive(
            minimumIncompleteLength: bodyLength,
            maximumLength: bodyLength,
            completion: { [weak self] (data, _, isComplete, error) in
                guard let self = self else {
                    return
                }

                if let data = data, data.count == bodyLength {
                    let message = BroadcastMessage(header: header, body: data)
                    self.delegate?.broadcastServer(self, didReceiveMessage: message)
                }

                if error == nil, !isComplete {
                    self.readHeader()
                } else {
                    self.stop(error: error)
                }
            }
        )
    }

    private func stop(error: Error?) {
        var stopError = error

        do {
            try stop()
        } catch {
            stopError = error
        }

        delegate?.broadcastServer(self, didStopWithError: stopError)
    }

    private func removeSocketFile() throws {
        if fileManager.fileExists(atPath: path) {
            try fileManager.removeItem(atPath: path)
        }
    }
}

#endif
