// MARK: - Protocol

protocol CallSessionFactoryProtocol {
    func callTransceiver() -> CallSessionProtocol
    func presentationReceiver() -> CallSessionProtocol
}

// MARK: - Implementation

struct CallSessionFactory: CallSessionFactoryProtocol {
    let participantId: UUID
    let iceServers: [String]
    let qualityProfile: QualityProfile
    let callMediaFeatures: MediaFeature
    let apiClient: CallSession.APIClient
    let logger: LoggerProtocol

    // MARK: - Internal

    func callTransceiver() -> CallSessionProtocol {
        let logger = self.logger[.call]
        return CallSession(
            participantId: participantId,
            qualityProfile: qualityProfile,
            isPresentation: false,
            mediaConnection: mediaConnection(
                withFeatures: callMediaFeatures,
                logger: logger
            ),
            apiClient: apiClient,
            logger: logger
        )
    }

    func presentationReceiver() -> CallSessionProtocol {
        let logger = self.logger[.remotePresentation]
        return CallSession(
            participantId: participantId,
            qualityProfile: qualityProfile,
            isPresentation: true,
            mediaConnection: mediaConnection(
                withFeatures: [.receiveVideo],
                logger: logger
            ),
            apiClient: apiClient,
            logger: logger
        )
    }

    // MARK: - Private

    private func mediaConnection(
        withFeatures features: MediaFeature,
        logger: CategoryLogger
    ) -> MediaConnection {
        WebRTCConnection(
            iceServers: iceServers,
            qualityProfile: qualityProfile,
            features: callMediaFeatures,
            logger: logger
        )
    }
}
