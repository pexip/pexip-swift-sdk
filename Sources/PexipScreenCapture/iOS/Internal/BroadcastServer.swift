#if os(iOS)

import Foundation
import Combine
import Network

/// Inter-process communication server based on AF_UNIX domain sockets
final class BroadcastServer: Publisher {
    typealias Output = Event
    typealias Failure = Never

    enum Event {
        case start
        case message(BroadcastMessage)
        case stop(Error?)
    }

    var isRunning: Bool {
        _isRunning.value
    }

    private let listener: NWListener
    private let filePath: String
    private let fileManager: FileManager
    private let receivedHandshake = Synchronized(false)
    private let callbackQueue = DispatchQueue(label: "com.pexip.PexipMedia.BroadcastServer")
    /// Accept only single connection.
    private var connection: NWConnection?
    private let subject = PassthroughSubject<Event, Never>()
    private let _isRunning = Synchronized(false)

    // MARK: - Init

    init(filePath: String, fileManager: FileManager = .default) throws {
        let params = NWParameters.tcp
        params.requiredLocalEndpoint = NWEndpoint.unix(path: filePath)

        self.listener = try NWListener(using: params)
        self.filePath = filePath
        self.fileManager = fileManager
    }

    deinit {
        try? stop()
    }

    // MARK: - Internal

    @discardableResult
    func start() throws -> Bool {
        guard !isRunning else {
            return false
        }

        do {
            try removeSocketFile()

            listener.stateUpdateHandler = { [weak self] state in
                guard let self else {
                    return
                }

                switch state {
                case .ready:
                    self._isRunning.mutate { $0 = true }
                    self.subject.send(.start)
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

        return true
    }

    func stop() throws {
        guard isRunning else {
            return
        }

        _isRunning.mutate { $0 = false }
        listener.stateUpdateHandler = nil
        listener.newConnectionHandler = nil
        connection?.stateUpdateHandler = nil

        if listener.state != .cancelled {
            listener.cancel()
        }

        if connection != nil {
            connection?.cancel()
            connection = nil
        }

        try removeSocketFile()
    }

    func receive<S: Subscriber>(subscriber: S) where S.Failure == Failure,
                                                     S.Input == Output {
        subject.subscribe(subscriber)
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
        connection?.receive { [weak self] data, _, isComplete, error in
            guard let self, data != nil else {
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
            completion: { [weak self] data, _, isComplete, error in
                guard let self else {
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
            completion: { [weak self] data, _, isComplete, error in
                guard let self else {
                    return
                }

                if let data, data.count == bodyLength {
                    let message = BroadcastMessage(header: header, body: data)
                    self.subject.send(.message(message))
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
        guard isRunning else {
            return
        }

        var stopError = error

        do {
            try stop()
        } catch {
            stopError = error
        }

        subject.send(.stop(stopError))
    }

    private func removeSocketFile() throws {
        if fileManager.fileExists(atPath: filePath) {
            try fileManager.removeItem(atPath: filePath)
        }
    }
}

#endif
