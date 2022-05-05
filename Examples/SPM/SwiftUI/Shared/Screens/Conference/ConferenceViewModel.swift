import Combine
import SwiftUI
import PexipInfinityClient
import PexipRTC
import PexipConference
import PexipMedia

final class ConferenceViewModel: ObservableObject {
    enum State {
        case preflight
        case connecting
        case connected
        case disconnected
    }

    enum Modal {
        case chat
        case participants
    }

    struct Presentation {
        let track: VideoTrack
        var presenterName: String?
    }

    @Published private(set) var state: State
    @Published private(set) var cameraEnabled = false
    @Published private(set) var microphoneEnabled = false
    @Published private(set) var modal: Modal?
    @Published private(set) var mainLocalVideoTrack: VideoTrack?
    @Published private(set) var mainRemoteVideoTrack: VideoTrack?
    @Published private(set) var presentationRemoteVideoTrack: VideoTrack?
    @Published private(set) var presenterName: String?
    var chat: Chat? { conference.chat }
    var roster: Roster { conference.roster }

    private let conference: Conference
    private let mediaConnection: WebRTCMediaConnection
    private var cancellables = Set<AnyCancellable>()
    private let onComplete: () -> Void
    private let videoPermission = MediaCapturePermission.video
    private let audioPermission = MediaCapturePermission.audio

    // MARK: - Init

    init(
        conference: Conference,
        mediaConnection: WebRTCMediaConnection,
        onComplete: @escaping () -> Void
    ) {
        self.conference = conference
        self.mediaConnection = mediaConnection
        self.onComplete = onComplete
        self.state = .preflight

        mediaConnection.sendMainAudio()
        mediaConnection.sendMainVideo()

        setCameraEnabled(videoPermission.isAuthorized)
        setMicrophoneEnabled(audioPermission.isAuthorized)
        addMediaConnectionEventListeners()
        addConferenceEventListeners()
    }

    // MARK: - Actions

    func join() {
        state = .connecting

        Task { @MainActor in
            do {
                await conference.join()
                try await mediaConnection.start()
            } catch {
                state = .preflight
                debugPrint(error)
            }
        }
    }

    func leave() {
        Task { @MainActor in
            mediaConnection.stop()
            await leaveConference()
        }
    }

    func cancel() {
        Task { @MainActor in
            mediaConnection.stop()
            await leaveConference()
            onComplete()
        }
    }

    func toggleCamera() {
        #if os(iOS)
        Task {
            try await mediaConnection.toggleMainCaptureCamera()
        }
        #endif
    }

    func setCameraEnabled(_ enabled: Bool) {
        Task { @MainActor in
            if enabled {
                if await videoPermission.requestAccess(
                    openSettingsIfNeeded: true
                ) == .authorized {
                    try await mediaConnection.startMainCapture()
                }
            } else {
                try await mediaConnection.stopMainCapture()
            }
        }
    }

    func setMicrophoneEnabled(_ enabled: Bool) {
        Task {
            if enabled {
                if await audioPermission.requestAccess(
                    openSettingsIfNeeded: true
                ) == .authorized {
                    try await mediaConnection.muteAudio(enabled)
                }
            } else {
                try await mediaConnection.muteAudio(enabled)
            }
        }
    }

    func setModal(_ modal: Modal?) {
        withAnimation {
            self.modal = modal
        }
    }

    // MARK: - Private

    private func addMediaConnectionEventListeners() {
        mediaConnection.statePublisher
            .sink { [weak self] event in
                guard let self = self else { return }
                switch event {
                case .new, .connecting:
                    self.state = .connecting
                case .connected:
                    self.state = .connected
                case .failed, .closed, .disconnected:
                    self.state = .disconnected
                    self.mediaConnection.stop()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                        self?.onComplete()
                    }
                case .unknown:
                    break
                }
            }
            .store(in: &cancellables)

        mediaConnection.$mainRemoteVideoTrack
            .assign(to: \.mainRemoteVideoTrack, on: self)
            .store(in: &cancellables)

        mediaConnection.$mainLocalVideoTrack
            .assign(to: \.mainLocalVideoTrack, on: self)
            .store(in: &cancellables)

        mediaConnection.$presentationRemoteVideoTrack
            .assign(to: \.presentationRemoteVideoTrack, on: self)
            .store(in: &cancellables)

        mediaConnection.$isAudioMuted
            .receive(on: DispatchQueue.main)
            .assign(to: \.microphoneEnabled, on: self)
            .store(in: &cancellables)

        mediaConnection.$isCapturingMainVideo
            .receive(on: DispatchQueue.main)
            .assign(to: \.cameraEnabled, on: self)
            .store(in: &cancellables)
    }

    private func addConferenceEventListeners() {
        conference.eventPublisher
            .sink { [weak self] event in
                guard let self = self else { return }

                do {
                    switch event {
                    case .presentationStart(let message):
                        self.presenterName = message.presenterName
                        try self.mediaConnection.startPresentationReceive()
                    case .presentationStop:
                        self.presenterName = nil
                        try self.mediaConnection.stopPresentationReceive()
                    case .clientDisconnected:
                        Task {
                            try await self.conference.leave()
                        }
                    }
                } catch {
                    debugPrint("Cannot handle conference event, error: \(error)")
                }
            }
            .store(in: &cancellables)
    }

    private func leaveConference() async {
        do {
            try await self.conference.leave()
        } catch {
            debugPrint(error)
        }
    }
}
