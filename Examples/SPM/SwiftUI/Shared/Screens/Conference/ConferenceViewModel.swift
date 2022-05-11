import Combine
import SwiftUI
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
    @Published private(set) var mainRemoteVideoTrack: VideoTrack?
    @Published private(set) var presentationRemoteVideoTrack: VideoTrack?
    @Published private(set) var presenterName: String?
    let cameraVideoTrack: CameraVideoTrack?
    let cameraQualityProfile: QualityProfile = .high
    let remoteVideoContentMode: VideoContentMode = .fit_16x9
    var chat: Chat? { conference.chat }
    var roster: Roster { conference.roster }

    private let conference: Conference
    private var mediaConnection: MediaConnection
    private let mainLocalAudioTrack: LocalAudioTrack
    private let onComplete: () -> Void
    private let videoPermission = MediaCapturePermission.video
    private let audioPermission = MediaCapturePermission.audio
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init(
        conference: Conference,
        mediaConnection: MediaConnection,
        cameraVideoTrack: CameraVideoTrack?,
        mainLocalAudioTrack: LocalAudioTrack,
        onComplete: @escaping () -> Void
    ) {
        self.conference = conference
        self.mediaConnection = mediaConnection
        self.cameraVideoTrack = cameraVideoTrack
        self.mainLocalAudioTrack = mainLocalAudioTrack
        self.onComplete = onComplete
        self.state = .preflight

        setCameraEnabled(videoPermission.isAuthorized)
        setMicrophoneEnabled(audioPermission.isAuthorized)
        addMediaConnectionEventListeners()
        addConferenceEventListeners()
    }

    // MARK: - Actions

    func join() {
        state = .connecting
        mediaConnection.sendMainAudio(localAudioTrack: mainLocalAudioTrack)

        if let cameraVideoTrack = cameraVideoTrack {
            mediaConnection.sendMainVideo(localVideoTrack: cameraVideoTrack)
        }

        Task { @MainActor in
            do {
                try await mediaConnection.start()
                await conference.receiveEvents()
            } catch {
                state = .preflight
                debugPrint(error)
            }
        }
    }

    func leave() {
        state = .disconnected

        Task {
            try await conference.leave()
            mediaConnection.stop()
            setCameraEnabled(false)
            setMicrophoneEnabled(false)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.onComplete()
            }
        }
    }

    func cancel() {
        setCameraEnabled(false)
        setMicrophoneEnabled(false)
        Task {
            try await conference.leave()
            onComplete()
        }
    }

    func toggleCamera() {
        #if os(iOS)
        Task {
            try await cameraVideoTrack?.toggleCamera()
        }
        #endif
    }

    func setCameraEnabled(_ enabled: Bool) {
        Task { @MainActor in
            if enabled {
                if await videoPermission.requestAccess(
                    openSettingsIfNeeded: true
                ) == .authorized {
                    try await cameraVideoTrack?.startCapture(
                        profile: cameraQualityProfile
                    )
                }
            } else {
                cameraVideoTrack?.stopCapture()
            }
        }
    }

    func setMicrophoneEnabled(_ enabled: Bool) {
        Task {
            if enabled {
                if await audioPermission.requestAccess(
                    openSettingsIfNeeded: true
                ) == .authorized {
                    try await mainLocalAudioTrack.startCapture()
                }
            } else {
                mainLocalAudioTrack.stopCapture()
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
                case .unknown:
                    break
                }
            }
            .store(in: &cancellables)

        mediaConnection.remoteVideoTracks.$mainTrack
            .receive(on: DispatchQueue.main)
            .assign(to: &$mainRemoteVideoTrack)

        mediaConnection.remoteVideoTracks.$presentationTrack
            .receive(on: DispatchQueue.main)
            .assign(to: &$presentationRemoteVideoTrack)

        cameraVideoTrack?.capturingStatus.$isCapturing
            .receive(on: DispatchQueue.main)
            .assign(to: &$cameraEnabled)

        mainLocalAudioTrack.capturingStatus.$isCapturing
            .receive(on: DispatchQueue.main)
            .assign(to: &$microphoneEnabled)
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
                        self.leave()
                    }
                } catch {
                    debugPrint("Cannot handle conference event, error: \(error)")
                }
            }
            .store(in: &cancellables)
    }
}
