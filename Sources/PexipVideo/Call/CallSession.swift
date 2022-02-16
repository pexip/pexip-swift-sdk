import Foundation
import Combine

// MARK: - Protocol

protocol CallSessionProtocol {
    func start() async throws
    func stop() async throws
}

// MARK: - Implementation

final class CallSession: CallSessionProtocol {
    typealias APIClient = CallClientProtocol
    private typealias CallDetailsTask = Task<CallDetails, Error>

    private let participantId: UUID
    private let configuration: CallConfiguration
    private let isPresentation: Bool
    private let apiClient: APIClient
    private let rtcClient: WebRTCClient
    private let logger: CategoryLogger
    private var callDetailsTask: CallDetailsTask?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init(
        participantId: UUID,
        configuration: CallConfiguration,
        isPresentation: Bool = false,
        iceServers: [String],
        apiClient: APIClient,
        logger: LoggerProtocol
    ) {
        self.participantId = participantId
        self.configuration = configuration
        self.isPresentation = isPresentation
        self.apiClient = apiClient
        self.rtcClient = WebRTCClient(
            iceServers: iceServers.isEmpty
                ? configuration.backupIceServers
                : iceServers,
            qualityProfile: configuration.qualityProfile,
            logger: logger
        )
        self.logger = logger[.media]
    }

    func start() async throws {
        let callDetailsTask = CallDetailsTask {
            let sdp = try await rtcClient.createOffer()
            let offer = SDPMangler(sdp: sdp).mangle(
                qualityProfile: configuration.qualityProfile,
                isPresentation: isPresentation
            )
            return try await apiClient.makeCall(
                participantId: participantId,
                sdp: offer,
                presentation: isPresentation ? .receive : nil
            )
        }
        self.callDetailsTask = callDetailsTask

        // Listen for local ICE candidates on the local peer connection
        rtcClient.iceCandidate
            .sink { [weak self] candidate in
                self?.sendNewIceCandidate(
                    candidate,
                    callDetailsTask: callDetailsTask
                )
            }.store(in: &cancellables)

        try await rtcClient.setRemoteDescription(callDetailsTask.value.sdp)

        let mediaStarted = try await apiClient.ack(
            participantId: participantId,
            callId: callDetailsTask.value.id
        )

        if mediaStarted {
            logger.info("Started media for the call.")
        } else {
            logger.warn("Failed to start media for the call.")
        }
    }

    func stop() async throws {
        guard let callDetailsTask = callDetailsTask else {
            return
        }

        callDetailsTask.cancel()
        self.callDetailsTask = nil
        rtcClient.close()
        cancellables = []

        let disconnected = try await apiClient.disconnect(
            participantId: participantId,
            callId: callDetailsTask.value.id
        )

        if disconnected {
            logger.info("Disconnected from the call.")
        } else {
            logger.warn("Failed to disconnect from the call.")
        }
    }

    // MARK: - Private

    private func sendNewIceCandidate(
        _ iceCandidate: IceCandidate,
        callDetailsTask: CallDetailsTask
    ) {
        Task {
            do {
                try await apiClient.newCandidate(
                    participantId: participantId,
                    callId: callDetailsTask.value.id,
                    iceCandidate: iceCandidate
                )
                logger.debug("Added new ICE candidate.")
            } catch {
                logger.error(
                    "Failed to send new ICE candidate: \(error.localizedDescription)"
                )
            }
        }
    }
}
