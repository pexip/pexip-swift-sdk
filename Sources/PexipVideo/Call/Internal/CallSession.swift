import Foundation
import Combine

// MARK: - Protocol

protocol CallSessionProtocol {
    var isPresentation: Bool { get }
    var audioTrack: LocalAudioTrackProtocol? { get }
    var localVideoTrack: LocalVideoTrackProtocol? { get }
    var remoteVideoTrack: VideoTrackProtocol? { get }
    var eventPublisher: AnyPublisher<CallEvent, Never> { get }

    func start() async throws
    func stop() async
}

// MARK: - Implementation

final class CallSession: CallSessionProtocol {
    typealias APIClient = CallClientProtocol & ParticipantClientProtocol
    private typealias CallDetailsTask = Task<CallDetails, Error>

    let isPresentation: Bool
    var audioTrack: LocalAudioTrackProtocol? { mediaConnection.audioTrack }
    var localVideoTrack: LocalVideoTrackProtocol? { mediaConnection.localVideoTrack }
    var remoteVideoTrack: VideoTrackProtocol? { mediaConnection.remoteVideoTrack }

    var eventPublisher: AnyPublisher<CallEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    private let participantId: UUID
    private let qualityProfile: QualityProfile
    private let apiClient: APIClient
    private let mediaConnection: MediaConnection
    private let logger: CategoryLogger
    private var callDetailsTask: CallDetailsTask?
    private var isConnected = false
    private var eventSubject = PassthroughSubject<CallEvent, Never>()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init(
        participantId: UUID,
        qualityProfile: QualityProfile,
        isPresentation: Bool,
        mediaConnection: MediaConnection,
        apiClient: APIClient,
        logger: CategoryLogger
    ) {
        self.participantId = participantId
        self.qualityProfile = qualityProfile
        self.isPresentation = isPresentation
        self.apiClient = apiClient
        self.mediaConnection = mediaConnection
        self.logger = logger
    }

    func start() async throws {
        // Listen for connection events
        mediaConnection.eventPublisher
            .sink { [weak self] event in
                self?.handleEvent(event)
            }.store(in: &cancellables)

        let callDetailsTask = CallDetailsTask {
            let sdp = try await mediaConnection.createOffer()
            let offer = SDPMangler(sdp: sdp).mangle(
                qualityProfile: qualityProfile,
                isPresentation: isPresentation
            )
            return try await apiClient.makeCall(
                participantId: participantId,
                sdp: offer,
                presentation: isPresentation ? .receive : nil
            )
        }
        self.callDetailsTask = callDetailsTask

        try await mediaConnection.setRemoteDescription(callDetailsTask.value.sdp)
    }

    func stop() async {
        guard let callDetailsTask = callDetailsTask else {
            return
        }

        callDetailsTask.cancel()
        self.callDetailsTask = nil
        mediaConnection.close()
        cancellables = []

        if isConnected {
            isConnected = false
            do {
                try await apiClient.disconnect(
                    participantId: participantId,
                    callId: callDetailsTask.value.id
                )
            } catch {
                logger.error("Call disconnect request failed with error: \(error)")
            }
        }

        logger.info("Disconnected from the call.")
    }

    // MARK: - Private

    private func handleEvent(_ event: MediaConnectionEvent) {
        Task {
            switch event {
            case .connected:
                do {
                    isConnected = try await startMedia()
                    eventSubject.send(isConnected ? .connected : .failed)
                } catch {
                    eventSubject.send(.failed)
                }
            case .disconnected:
                eventSubject.send(.disconnected)
            case .closed:
                eventSubject.send(.closed)
            case .failed:
                logger.error("Peer connection failed")
            case .newIceCandidate(let iceCandidate):
                await sendNewIceCandidate(iceCandidate)
            }
        }
    }

    private func startMedia() async throws -> Bool {
        guard let callDetailsTask = callDetailsTask else {
            logger.warn("Tried to start media before starting a call")
            return false
        }

        let started = try await apiClient.ack(
            participantId: participantId,
            callId: callDetailsTask.value.id
        )

        if started {
            logger.info("Started media for the call.")
        } else {
            logger.warn("Failed to start media for the call.")
        }

        return started
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
                "Failed to send new ICE candidate: \(error)"
            )
        }
    }
}
