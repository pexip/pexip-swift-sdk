import Combine
import SwiftUI
import PexipRTC
import PexipConference
import PexipMedia

enum ConferenceState {
    case preflight
    case connecting
    case connected
    case disconnected
}

enum ConferenceModal {
    case chat
    case participants
}

final class ConferenceViewModel: ObservableObject {
    @Published private(set) var state: ConferenceState
    @Published private(set) var cameraEnabled = false
    @Published private(set) var microphoneEnabled = false
    @Published private(set) var isPresenting = false
    @Published private(set) var modal: ConferenceModal?
    @Published private(set) var presenterName: String?

    var mainRemoteVideo: Video? {
        mainRemoteVideoTrack.map {
            Video(track: $0, contentMode: remoteVideoContentMode)
        }
    }

    var mainLocalVideo: Video? {
        cameraVideoTrack.map {
            Video(track: $0, qualityProfile: cameraQualityProfile)
        }
    }

    var presentationLocalVideo: Video? {
        screenMediaTrack.map {
            Video(track: $0, qualityProfile: localPresentationQualityProfile)
        }
    }

    var presentationRemoteVideo: Video? {
        presentationRemoteVideoTrack.map {
            Video(track: $0, contentMode: remoteVideoContentMode)
        }
    }

    let remoteVideoContentMode = VideoContentMode.fit_16x9
    var chat: Chat? { conference.chat }
    var roster: Roster { conference.roster }

    private let conference: Conference
    private let mediaConnectionFactory: MediaConnectionFactory
    private var mediaConnection: MediaConnection
    private let mainLocalAudioTrack: LocalAudioTrack
    private let cameraVideoTrack: CameraVideoTrack?
    private let onComplete: () -> Void
    private let videoPermission = MediaCapturePermission.video
    private let audioPermission = MediaCapturePermission.audio
    private var cancellables = Set<AnyCancellable>()
    private let cameraQualityProfile: QualityProfile = .high
    private let localPresentationQualityProfile: QualityProfile = .presentationVeryHigh
    @Published private var mainRemoteVideoTrack: VideoTrack?
    @Published private var presentationRemoteVideoTrack: VideoTrack?
    @Published private var screenMediaTrack: ScreenMediaTrack?

    // MARK: - Init

    init(
        conference: Conference,
        mediaConnectionConfig: MediaConnectionConfig,
        mediaConnectionFactory: MediaConnectionFactory,
        onComplete: @escaping () -> Void
    ) {
        self.conference = conference
        self.mediaConnectionFactory = mediaConnectionFactory
        self.mediaConnection = mediaConnectionFactory.createMediaConnection(
            config: mediaConnectionConfig
        )
        self.cameraVideoTrack = mediaConnectionFactory.createCameraVideoTrack()
        self.mainLocalAudioTrack = mediaConnectionFactory.createLocalAudioTrack()
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
        mediaConnection.setMainAudioTrack(mainLocalAudioTrack)
        mediaConnection.setMainVideoTrack(cameraVideoTrack)

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
                        withVideoProfile: cameraQualityProfile
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

    #if os(iOS)

    func startPresenting() {
        let track = mediaConnectionFactory.createScreenMediaTrack(
            appGroup: Constants.appGroup,
            broadcastUploadExtension: Constants.broadcastUploadExtension
        )
        startScreenCapture(withTrack: track)
    }

    #else

    func startPresenting(_ screenMediaSource: ScreenMediaSource) {
        let track = mediaConnectionFactory.createScreenMediaTrack(
            mediaSource: screenMediaSource
        )
        startScreenCapture(withTrack: track)
    }
    #endif

    func stopPresenting() {
        screenMediaTrack?.stopCapture()
        screenMediaTrack = nil
        mediaConnection.setScreenMediaTrack(nil)
        isPresenting = false
    }

    func setModal(_ modal: ConferenceModal?) {
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
                        self.stopPresenting()
                        self.presenterName = message.presenterName
                        try self.mediaConnection.receivePresentation(true)
                    case .presentationStop:
                        self.presenterName = nil
                        try self.mediaConnection.receivePresentation(false)
                    case .clientDisconnected:
                        self.leave()
                    }
                } catch {
                    debugPrint("Cannot handle conference event, error: \(error)")
                }
            }
            .store(in: &cancellables)
    }

    private func startScreenCapture(withTrack screenMediaTrack: ScreenMediaTrack) {
        self.screenMediaTrack = screenMediaTrack

        screenMediaTrack.capturingStatus.$isCapturing
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isCapturing in
                guard let self  = self else { return }

                if !isCapturing && self.isPresenting {
                    self.screenMediaTrack = nil
                    self.mediaConnection.setScreenMediaTrack(nil)
                }

                self.isPresenting = isCapturing
            }
            .store(in: &cancellables)

        Task {
            do {
                mediaConnection.setScreenMediaTrack(screenMediaTrack)
                try await screenMediaTrack.startCapture(
                    withVideoProfile: localPresentationQualityProfile
                )
            } catch {
                stopPresenting()
                debugPrint(error)
            }
        }
    }
}
