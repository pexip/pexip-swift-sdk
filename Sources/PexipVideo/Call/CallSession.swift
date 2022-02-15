import Foundation

// MARK: - Protocol

protocol CallSessionProtocol {
    func start() async throws
    func stop() async throws
}

// MARK: - Implementation

final class CallSession: CallSessionProtocol {
    typealias APIClient = CallClientProtocol

    private let participantId: UUID
    private let configuration: CallConfiguration
    private let apiClient: APIClient
    private let rtcClient: WebRTCClient
    private var callId: UUID?

    // MARK: - Init

    init(
        participantId: UUID,
        configuration: CallConfiguration,
        iceServers: [String],
        apiClient: APIClient,
        logger: LoggerProtocol
    ) {
        self.participantId = participantId
        self.configuration = configuration
        self.apiClient = apiClient
        self.rtcClient = WebRTCClient(
            iceServers: iceServers.isEmpty
                ? configuration.backupIceServers
                : iceServers,
            qualityProfile: configuration.qualityProfile,
            logger: logger
        )
    }

    func start() async throws {
        let sdp = try await rtcClient.createOffer()
        let offer = SDPMangler(sdp: sdp).sdp(
            withBandwidth: configuration.qualityProfile.bandwidth,
            isPresentation: false
        )
        let callDetails = try await apiClient.makeCall(
            participantId: participantId,
            sdp: offer,
            present: nil
        )

        try await rtcClient.setRemoteDescription(callDetails.sdp)

        _ = try await apiClient.ack(
            participantId: participantId,
            callId: callDetails.id
        )
    }

    func stop() async throws {
        guard let callId = callId else {
            return
        }

        rtcClient.close()

        _ = try await apiClient.disconnect(
            participantId: participantId,
            callId: callId
        )
    }
}
