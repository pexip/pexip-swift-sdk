import PexipInfinityClient

// MARK: - Protocol

protocol DTMFSender {
    func send(dtmf: DTMFSignals) async throws -> Bool
}

// MARK: - Implementation

struct DefaultDTMFSender: DTMFSender {
    let tokenStore: TokenStore<ConferenceToken>
    let participantService: ParticipantService

    func send(dtmf: DTMFSignals) async throws -> Bool {
        let token = try await tokenStore.token()
        return try await participantService.dtmf(
            signals: dtmf,
            token: token
        )
    }
}
