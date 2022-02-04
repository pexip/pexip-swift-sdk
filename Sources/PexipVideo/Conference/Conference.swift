import Foundation

public final class Conference {
    /// Resolves a conference with the given name.
    ///
    /// - Parameter name: Conference name in the form of conference@domain.org
    /// - Parameter logger: An object for writing string messages to the logging system of choice
    public static func resolveConference(
        withName name: ConferenceName,
        logger: LoggerProtocol = DefaultLogger()
    ) async throws -> Conference {
        let nodeResolver = ServiceLocator.makeNodeResolver(logger: logger)
        let nodeAddress = try await nodeResolver.resolveNodeAddress(for: name.domain)

        logger[.dnsLookup].info(
            "Found a conferencing node with address: \(nodeAddress.absoluteString)"
        )

        let configuration = APIConfiguration(nodeAddress: nodeAddress, alias: name.alias)
        let serviceLocator = ServiceLocator(
            logger: logger,
            apiConfiguration: configuration
        )

        return Conference(serviceLocator: serviceLocator)
    }

    private let name: String
    private let serviceLocator: ServiceLocator
    private let session: AuthSession
    private let eventSourceClient: SSEClientProtocol
    private let logger: CategoryLogger
    private var eventStreamTask: Task<Void, Never>?

    // MARK: - Init

    init(serviceLocator: ServiceLocator) {
        self.name = serviceLocator.apiConfiguration.alias
        self.serviceLocator = serviceLocator
        self.session = serviceLocator.makeAuthSession()
        self.eventSourceClient = serviceLocator.makeEventSourceClient()
        self.logger = serviceLocator.logger[.conference]
    }

    // MARK: - Public API

    /// Connects to the Pexip Conferencing Node.
    ///
    /// - Parameters:
    ///   - displayName: The name by which this participant should be known
    ///   - pin: User-supplied PIN (if required)
    ///   - conferenceExtension: Conference to connect to (when being used with a Virtual Reception)
    public func connect(
        displayName: String,
        pin: String? = nil,
        conferenceExtension: String? = nil
    ) async throws {
        logger.info("Joining \(name) as \(displayName)")

        try await session.activate(
            displayName: displayName,
            pin: pin,
            conferenceExtension: conferenceExtension
        )

        try await eventSourceClient.connect()

        eventStreamTask = Task {
            for await event in await eventSourceClient.eventStream() {
                handleEvent(event)
            }
        }
    }

    public func disconnect() async throws {
        logger.info("Leaving \(name)")
        try await session.deactivate()
        eventStreamTask?.cancel()
        await eventSourceClient.disconnect()
    }

    // MARK: - Private methods

    private func handleEvent(_ event: ConferenceEvent) {
        switch event {
        case .chatMessage:
            break
        }
    }
}
