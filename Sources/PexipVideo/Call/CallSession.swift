import Foundation
import Combine

// MARK: - Protocol

enum CallEvent {
    case mediaStarted
    case mediaEnded
}

protocol CallSessionProtocol {
    var audioTrack: AudioTrackProtocol? { get }
    var localVideoTrack: LocalVideoTrackProtocol? { get }
    var remoteVideoTrack: VideoTrackProtocol? { get }
    var eventPublisher: AnyPublisher<CallEvent, Never> { get }

    func start() async throws
    func stop() async throws
}

// MARK: - Implementation

final class CallSession: CallSessionProtocol {
    typealias APIClient = CallClientProtocol & ParticipantClientProtocol
    private typealias CallDetailsTask = Task<CallDetails, Error>

    var audioTrack: AudioTrackProtocol? { rtcClient.audioTrack }
    var localVideoTrack: LocalVideoTrackProtocol? { rtcClient.localVideoTrack }
    var remoteVideoTrack: VideoTrackProtocol? { rtcClient.remoteVideoTrack }

    var eventPublisher: AnyPublisher<CallEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    private let participantId: UUID
    private let configuration: CallConfiguration
    private let isPresentation: Bool
    private let apiClient: APIClient
    private let rtcClient: WebRTCClient
    private let logger: CategoryLogger
    private var callDetailsTask: CallDetailsTask?
    private var eventSubject = PassthroughSubject<CallEvent, Never>()
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
            supportsAudio: configuration.supportsAudio,
            supportsVideo: configuration.supportsVideo,
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

        // Listen for connection events
        rtcClient.eventPublisher
            .sink { [weak self] event in
                self?.handleEvent(event)
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

        try await apiClient.disconnect(
            participantId: participantId,
            callId: callDetailsTask.value.id
        )

        logger.info("Disconnected from the call.")
    }

    // MARK: - Private

    private func handleEvent(_ event: CallConnectionEvent) {
        Task {
            switch event {
            case .connected:
                eventSubject.send(.mediaStarted)
            case .disconnected:
                eventSubject.send(.mediaEnded)
            case .failed:
                logger.error("Peer connection failed")
            case .newIceCandidate(let iceCandidate):
                await sendNewIceCandidate(iceCandidate)
            }
        }
    }

    /// Listen for local ICE candidates on the local peer connection
    private func sendNewIceCandidate(_ iceCandidate: IceCandidate) async {
        guard let callDetailsTask = callDetailsTask else {
            logger.warn("Tried to send a new ICE candidate before starting a call")
            return
        }

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
