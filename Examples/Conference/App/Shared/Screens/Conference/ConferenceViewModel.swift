//
// Copyright 2022-2023 Pexip AS
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Combine
import SwiftUI
import PexipRTC
import PexipMedia
import PexipInfinityClient
import PexipVideoFilters
import PexipScreenCapture

// swiftlint:disable file_length
final class ConferenceViewModel: ObservableObject {
    typealias Complete = (Completion) -> Void

    enum Completion {
        case exit
        case transfer(ConferenceDetails)
    }

    @AppStorage("displayName") private var displayName = "Guest"
    @Published private(set) var state: ConferenceState
    @Published private(set) var splashScreen: SplashScreen?
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
        if isPresenting {
            return screenMediaTrack.map {
                Video(track: $0, qualityProfile: localPresentationQualityProfile)
            }
        } else {
            return nil
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

    let remoteVideoContentMode = VideoContentMode.fit
    var hasChat: Bool { conference.chat != nil }
    var roster: Roster { conference.roster }
    private(set) lazy var chatMessageStore = conference.chat.map {
        ChatMessageStore(chat: $0, roster: roster)
    }

    private let conference: Conference
    private let conferenceConnector: ConferenceConnector
    private let settings: Settings
    private let mediaFactory: MediaFactory
    private let mediaConnectionConfig: MediaConnectionConfig
    private var mediaConnection: MediaConnection
    private let mainLocalAudioTrack: LocalAudioTrack
    private var cameraVideoTrack: CameraVideoTrack?
    private var screenMediaTrack: ScreenMediaTrack?
    private let onComplete: Complete
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
    @Published private(set) var finalCaptions = [String]()
    @Published private(set) var currentCaptions = [String]()

    // MARK: - Init

    init(
        conference: Conference,
        conferenceConnector: ConferenceConnector,
        mediaConnectionConfig: MediaConnectionConfig,
        mediaFactory: MediaFactory,
        preflight: Bool,
        settings: Settings,
        onComplete: @escaping Complete
    ) {
        self.conference = conference
        self.conferenceConnector = conferenceConnector
        self.settings = settings
        self.mediaFactory = mediaFactory
        self.mediaConnectionConfig = mediaConnectionConfig
        self.mediaConnection = mediaFactory.createMediaConnection(
            config: mediaConnectionConfig
        )
        self.cameraVideoTrack = mediaFactory.createCameraVideoTrack()
        self.mainLocalAudioTrack = mediaFactory.createLocalAudioTrack()
        #if os(iOS)
        self.screenMediaTrack = mediaFactory.createScreenMediaTrack(
            appGroup: Constants.appGroup,
            broadcastUploadExtension: Constants.broadcastUploadExtension,
            defaultVideoProfile: localPresentationQualityProfile
        )
        #endif
        self.onComplete = onComplete
        self.state = .preflight

        setCameraEnabled(videoPermission.isAuthorized)
        setMicrophoneEnabled(audioPermission.isAuthorized)
        sinkMediaConnectionEvents()
        sinkConferenceEvents()
        sinkCameraFilterSettings()
        #if os(iOS)
        if let screenMediaTrack {
            sinkScreenCaptureEvents(from: screenMediaTrack)
        }
        #endif

        conference.receiveEvents()

        if !preflight {
            join()
        }
    }

    deinit {
        hideCaptionsTask?.cancel()
        hideCaptionsTask = nil
    }
}

// MARK: - Actions

extension ConferenceViewModel {
    func join() {
        Task { @MainActor in
            do {
                state = .connecting
                mediaConnection.setMainAudioTrack(mainLocalAudioTrack)
                mediaConnection.setMainVideoTrack(cameraVideoTrack)
                try await mediaConnection.start()
            } catch {
                state = .preflight
                debugPrint(error)
            }
        }
    }

    func leave() {
        state = .disconnected
        stopPresenting(reason: .callEnded)

        Task {
            await conference.leave()
            mediaConnection.stop()
            setCameraEnabled(false)
            setMicrophoneEnabled(false)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.onComplete(.exit)
            }
        }
    }

    func cancel() {
        setCameraEnabled(false)
        setMicrophoneEnabled(false)
        Task {
            await conference.leave()
            onComplete(.exit)
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
        startScreenCapture()
    }

    #else

    func startPresenting(_ screenMediaSource: ScreenMediaSource) {
        screenMediaTrack = mediaFactory.createScreenMediaTrack(
            mediaSource: screenMediaSource,
            defaultVideoProfile: localPresentationQualityProfile
        )
        sinkScreenCaptureEvents(from: screenMediaTrack!)
        startScreenCapture()
    }
    #endif

    func stopPresenting() {
        stopPresenting(reason: nil)
    }

    func stopPresenting(reason: ScreenCaptureStopReason?) {
        screenMediaTrack?.stopCapture(reason: reason)
        #if os(macOS)
        screenMediaTrack = nil
        #endif
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
        settings.$showLiveCaptions.sink { [weak self] show in
            self?.toggleLiveCaptions(show)
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

    func sinkScreenCaptureEvents(from track: ScreenMediaTrack) {
        track.capturingStatus.$isCapturing
            .dropFirst()
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isCapturing in
                guard let self else { return }

                if isCapturing {
                    self.mediaConnection.setScreenMediaTrack(track)
                } else {
                    self.mediaConnection.setScreenMediaTrack(nil)
                    #if os(macOS)
                    self.screenMediaTrack = nil
                    #endif
                }

                self.isPresenting = isCapturing
            }
            .store(in: &cancellables)
    }

    // swiftlint:disable cyclomatic_complexity
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
                        self.stopPresenting(reason: .presentationStolen)
                        self.presenterName = message.presenterName
                        try self.mediaConnection.receivePresentation(true)
                    case .presentationStop:
                        self.presenterName = nil
                        try self.mediaConnection.receivePresentation(false)
                    case .clientDisconnected:
                        self.leave()
                    case .splashScreen(let splashScreen):
                        self.splashScreen = splashScreen
                    case .failure(let message):
                        debugPrint("Received conference error event: \(message.error)")
                    case .peerDisconnected:
                        self.onPeerDisconnected()
                    case .refer(let event):
                        self.onRefer(event)
                    case .callDisconnected:
                        break
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
    func startScreenCapture() {
        guard let screenMediaTrack else {
            return
        }

        Task {
            do {
                try await screenMediaTrack.startCapture(
                    withVideoProfile: localPresentationQualityProfile
                )
            } catch {
                stopPresenting()
                debugPrint(error)
            }
        }
    }

    func setCameraFilter(_ filter: CameraVideoFilter?) {
        cameraVideoTrack?.videoFilter = videoFilterFactory.videoFilter(for: filter)
    }

    func toggleLiveCaptions(_ show: Bool) {
        Task {
            do {
                try await conference.toggleLiveCaptions(show)
            } catch {
                debugPrint(error)
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

    /// Create new media connection object
    /// when another peer is disconnected from a direct media call.
    private func onPeerDisconnected() {
        mediaConnection.stop()
        mediaConnection = mediaFactory.createMediaConnection(
            config: mediaConnectionConfig
        )
        sinkMediaConnectionEvents()
        join()
    }

    /// Call transfer logic:
    /// - leave the current conference (release token, unsubscribe from events, etc)
    /// - stop media connection
    /// - request new conference token using the one time token from the event
    /// - create new conference and media connection objects
    private func onRefer(_ event: ReferEvent) {
        Task { @MainActor in
            do {
                await conference.leave()
                mediaConnection.stop()
                let details = try await conferenceConnector.join(
                    using: .incomingToken(event.token),
                    displayName: displayName,
                    conferenceAlias: event.alias
                )
                onComplete(.transfer(details))
            } catch {
                leave()
            }
        }
    }
}
