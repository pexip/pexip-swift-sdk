import PexipInfinityClient

// MARK: - Protocol

protocol LiveCaptionsService {
    func toggleLiveCaptions(
        _ show: Bool,
        conferenceStatus: ConferenceStatus
    ) async throws -> Bool
}

// MARK: - Implementation

struct DefaultLiveCaptionsService: LiveCaptionsService {
    let tokenStore: TokenStore<ConferenceToken>
    let participantService: ParticipantService

    func toggleLiveCaptions(
        _ show: Bool,
        conferenceStatus: ConferenceStatus
    ) async throws -> Bool {
        guard conferenceStatus.liveCaptionsAvailable else {
            return false
        }

        let token = try await tokenStore.token()

        if show {
            try await participantService.showLiveCaptions(token: token)
        } else {
            try await participantService.hideLiveCaptions(token: token)
        }

        return true
    }
}
