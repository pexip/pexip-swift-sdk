import Foundation

public final class Conference {
    /// - Parameter uri: Conference URI in the form of conference@domain.org
    public static func configuration(
        for uri: ConferenceURI
    ) async throws -> ConferenceConfiguration {
        let nodeResolver = ServiceLocator.makeNodeResolver()
        let nodeAddress = try await nodeResolver.resolveNodeAddress(for: uri.domain)
        return ConferenceConfiguration(nodeAddress: nodeAddress, alias: uri.alias)
    }
        
    private let serviceLocator: ServiceLocator
    private let session: AuthSession
    private let eventSourceClient: SSEClientProtocol
    private var eventStreamTask: Task<Void, Never>?
    
    // MARK: - Init
    
    public convenience init(configuration: ConferenceConfiguration) {
        let serviceLocator = ServiceLocator(apiConfiguration: configuration)
        self.init(serviceLocator: serviceLocator)
    }
    
    init(serviceLocator: ServiceLocator) {
        self.serviceLocator = serviceLocator
        self.session = serviceLocator.makeAuthSession()
        self.eventSourceClient = serviceLocator.makeEventSourceClient()
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
        try await session.deactivate()
        eventStreamTask?.cancel()
        await eventSourceClient.disconnect()
    }
    
    // MARK: - Private methods
    
    private func handleEvent(_ event: ConferenceEvent) {
        switch event {
        case .chatMessage(let chatMessage):
            print(chatMessage)
        }
    }
}
