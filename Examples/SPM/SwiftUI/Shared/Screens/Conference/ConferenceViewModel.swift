import Combine
import SwiftUI
import PexipRTC
import PexipConference
import PexipMedia
import PexipInfinityClient

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

    var captions: String {
        (finalCaptions + currentCaptions).joined(separator: "\n")
    }

    let remoteVideoContentMode = VideoContentMode.fit_16x9
    var hasChat: Bool { conference.chat != nil }
    var roster: Roster { conference.roster }
    private(set) lazy var chatMessageStore = conference.chat.map {
        ChatMessageStore(chat: $0, roster: roster)
    }

    private let conference: Conference
    private let settings: Settings
    private let mediaConnectionFactory: MediaConnectionFactory
    private var mediaConnection: MediaConnection
    private let mainLocalAudioTrack: LocalAudioTrack
    private var cameraVideoTrack: CameraVideoTrack?
    private let onComplete: () -> Void
    private let videoPermission = MediaCapturePermission.video
    private let audioPermission = MediaCapturePermission.audio
    private var cancellables = Set<AnyCancellable>()
    private let cameraQualityProfile: QualityProfile = .high
    private let localPresentationQualityProfile: QualityProfile = .presentationVeryHigh
    private let videoFilterFactory = VideoFilterFactory()
    private var isSinkingLiveCaptionsSettings = false
    private var hideCaptionsTask: Task<Void, Error>?
    @Published private var mainRemoteVideoTrack: VideoTrack?
    @Published private var presentationRemoteVideoTrack: VideoTrack?
    @Published private var screenMediaTrack: ScreenMediaTrack?
    @Published private(set) var finalCaptions = [String]()
    @Published private(set) var currentCaptions = [String]()

    // MARK: - Init

    init(
        conference: Conference,
        mediaConnectionConfig: MediaConnectionConfig,
        mediaConnectionFactory: MediaConnectionFactory,
        settings: Settings,
        onComplete: @escaping () -> Void
    ) {
        self.conference = conference
        self.settings = settings
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
        sinkMediaConnectionEvents()
        sinkConferenceEvents()
        sinkCameraFilterSettings()
    }

    deinit {
        hideCaptionsTask?.cancel()
        hideCaptionsTask = nil
    }
}

// MARK: - Actions

extension ConferenceViewModel {
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
}

// MARK: - Subscriptions

private extension ConferenceViewModel {
    func sinkCameraFilterSettings() {
        settings.$cameraFilter.sink { [weak self] filter in
            self?.setCameraFilter(filter)
        }.store(in: &cancellables)
    }

    func sinkLiveCaptionsSettings() {
        guard !isSinkingLiveCaptionsSettings else {
            return
        }

        isSinkingLiveCaptionsSettings = true

        settings.$showLiveCaptions.sink { show in
            Task { [weak self] in
                do {
                    try await self?.conference.toggleLiveCaptions(show)
                } catch {
                    debugPrint(error)
                }
            }
        }.store(in: &cancellables)
    }

    func sinkMediaConnectionEvents() {
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

    func sinkConferenceEvents() {
        conference.eventPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                guard let self = self else { return }

                do {
                    switch event {
                    case .conferenceUpdate(let status):
                        self.settings.isLiveCaptionsAvailable = status.liveCaptionsAvailable
                        self.sinkLiveCaptionsSettings()
                    case .liveCaptions(let captions):
                        self.showLiveCaptions(captions)
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
}

// MARK: - Private

private extension ConferenceViewModel {
    func startScreenCapture(withTrack screenMediaTrack: ScreenMediaTrack) {
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

    func setCameraFilter(_ filter: CameraFilter) {
        let factory = videoFilterFactory

        switch filter {
        case .none:
            cameraVideoTrack?.videoFilter = nil
        case .gaussianBlur:
            cameraVideoTrack?.videoFilter = factory.gaussianBlur(radius: 30)
        case .tentBlur:
            cameraVideoTrack?.videoFilter = factory.tentBlur(intensity: 0.3)
        case .boxBlur:
            cameraVideoTrack?.videoFilter = factory.boxBlur(intensity: 0.3)
        case .imageBackground:
            if let image = CGImage.withName("background_image") {
                cameraVideoTrack?.videoFilter = factory.virtualBackground(image: image)
            } else {
                cameraVideoTrack?.videoFilter = nil
            }
        }
    }

    func showLiveCaptions(_ captions: LiveCaptions) {
        if captions.isFinal {
            currentCaptions.removeAll()
            finalCaptions.append(captions.data)
            if finalCaptions.count > 2 {
                finalCaptions.removeFirst()
            }
        } else {
            currentCaptions = [captions.data]
            if finalCaptions.count > 1 {
                finalCaptions.removeFirst()
            }
        }

        hideCaptionsTask?.cancel()
        hideCaptionsTask = Task { @MainActor in
            try await Task.sleep(nanoseconds: UInt64(5 * 1_000_000_000))
            finalCaptions.removeAll()
            currentCaptions.removeAll()
        }
    }
}
