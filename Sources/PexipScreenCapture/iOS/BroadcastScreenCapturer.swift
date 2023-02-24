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

#if os(iOS)

import CoreVideo
import Combine
import ReplayKit

/// A capturer that captures the screen content from Broadcast Upload Extension on iOS.
public final class BroadcastScreenCapturer: ScreenMediaCapturer {
    static let keepAliveInterval: TimeInterval = 2

    public weak var delegate: ScreenMediaCapturerDelegate?

    private let broadcastUploadExtension: String
    private let defaultFps: UInt
    private var videoReceiver: BroadcastVideoReceiver
    private let notificationCenter = BroadcastNotificationCenter.default
    private let userDefaults: UserDefaults?
    private let isCapturing = Synchronized(false)
    private var keepAliveTimer: DispatchSourceTimer?
    private let keepAliveTimerQueue = DispatchQueue(
        label: "com.pexip.PexipScreenCapture.BroadcastScreenCapturer.keepAliveTimer",
        qos: .default
    )
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    /**
     Creates a new instance of ``BroadcastScreenCapturer``
     - Parameters:
        - appGroup: The app group identifier
        - broadcastUploadExtension: Bundle identifier of your broadcast upload extension
        - defaultFps: The default fps to use when screen capture starts automatically
                      (e.g. from the Control Center on iOS)
        - fileManager: An optional instance of the file manager
     */
    public convenience init(
        appGroup: String,
        broadcastUploadExtension: String,
        defaultFps: UInt = 15,
        fileManager: FileManager = .default
    ) {
        self.init(
            broadcastUploadExtension: broadcastUploadExtension,
            defaultFps: defaultFps,
            videoReceiver: BroadcastVideoReceiver(
                filePath: fileManager.broadcastVideoDataPath(appGroup: appGroup),
                fileManager: fileManager
            ),
            userDefaults: UserDefaults(suiteName: appGroup)
        )
    }

    init(
        broadcastUploadExtension: String,
        defaultFps: UInt,
        videoReceiver: BroadcastVideoReceiver,
        keepAliveInterval: TimeInterval = BroadcastScreenCapturer.keepAliveInterval,
        userDefaults: UserDefaults?
    ) {
        self.broadcastUploadExtension = broadcastUploadExtension
        self.defaultFps = defaultFps
        self.videoReceiver = videoReceiver
        self.userDefaults = userDefaults

        userDefaults?.broadcastFps = defaultFps
        videoReceiver.delegate = self
        addNotificationObservers()
        startKeepAliveTimer(withInterval: keepAliveInterval)
    }

    deinit {
        try? stopCapture()
        stopKeepAliveTimer()
        removeNotificationObservers()
        userDefaults?.broadcastFps = nil
    }

    // MARK: - Internal

    /**
     Starts screen capture with the given fps.
     - Parameters:
        - fps: The FPS of a video stream (15...30)
     */
    public func startCapture(atFps fps: UInt) async throws {
        guard !isCapturing.value else {
            return
        }

        userDefaults?.broadcastFps = fps

        let broadcastUploadExtension = self.broadcastUploadExtension

        DispatchQueue.main.async {
            let view = RPSystemBroadcastPickerView()
            view.preferredExtension = broadcastUploadExtension
            view.showsMicrophoneButton = false

            let button = view.subviews.first(where: { $0 is UIButton }) as? UIButton
            button?.sendActions(for: .touchUpInside)
        }
    }

    public func stopCapture() throws {
        try stopCapture(reason: nil)
    }

    public func stopCapture(reason: ScreenCaptureStopReason?) throws {
        guard isCapturing.value else {
            return
        }

        try stopVideoReceiver()

        switch reason {
        case .none:
            notificationCenter.post(.receiverFinished)
        case .presentationStolen:
            notificationCenter.post(.presentationStolen)
        case .callEnded:
            notificationCenter.post(.callEnded)
        }
    }

    // MARK: - Private

    private func addNotificationObservers() {
        notificationCenter.addObserver(self, for: .senderStarted) { [weak self] in
            if self?.isCapturing.value == false {
                self?.startVideoReceiver()
            }
        }

        notificationCenter.addObserver(self, for: .senderFinished) { [weak self] in
            guard self?.isCapturing.value == true else {
                return
            }

            var stopError: Error?

            do {
                try self?.stopVideoReceiver()
            } catch {
                stopError = error
            }

            self?.onStop(error: stopError)
        }
    }

    private func removeNotificationObservers() {
        notificationCenter.removeObserver(self)
    }

    private func startVideoReceiver() {
        do {
            try videoReceiver.start(withFps: BroadcastFps(value: userDefaults?.broadcastFps))
            isCapturing.setValue(true)
            notificationCenter.post(.receiverStarted)
            delegate?.screenMediaCapturerDidStart(self)
        } catch {
            userDefaults?.broadcastFps = defaultFps
            notificationCenter.post(.receiverFinished)
            onStop(error: error)
        }
    }

    private func stopVideoReceiver() throws {
        try videoReceiver.stop()
        userDefaults?.broadcastFps = defaultFps
        isCapturing.setValue(false)
    }

    /// Write current date to shared UserDefaults to indicate that
    /// the broadcast capturer is waiting for new connections.
    private func startKeepAliveTimer(withInterval interval: TimeInterval) {
        stopKeepAliveTimer()
        keepAliveTimer = DispatchSource.makeTimerSource(
            flags: .strict,
            queue: keepAliveTimerQueue
        )
        keepAliveTimer?.setEventHandler(handler: { [weak self] in
            self?.userDefaults?.broadcastKeepAliveDate = Date()
        })
        keepAliveTimer?.schedule(
            deadline: .now(),
            repeating: .nanoseconds(Int(interval * Double(NSEC_PER_SEC)))
        )
        keepAliveTimer?.activate()
    }

    private func stopKeepAliveTimer() {
        keepAliveTimer?.cancel()
        keepAliveTimer = nil
        userDefaults?.broadcastKeepAliveDate = nil
    }

    private func onStop(error: Error?) {
        delegate?.screenMediaCapturer(self, didStopWithError: error)
    }

    private func onCapture(videoFrame: VideoFrame) {
        delegate?.screenMediaCapturer(self, didCaptureVideoFrame: videoFrame)
    }
}

// MARK: - BroadcastVideoReceiverDelegate

extension BroadcastScreenCapturer: BroadcastVideoReceiverDelegate {
    func broadcastVideoReceiver(
        _ receiver: BroadcastVideoReceiver,
        didReceiveVideoFrame videoFrame: VideoFrame
    ) {
        onCapture(videoFrame: videoFrame)
    }
}

#endif
