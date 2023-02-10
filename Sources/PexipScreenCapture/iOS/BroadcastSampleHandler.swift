#if os(iOS)

import Combine
import CoreMedia
import ReplayKit

// MARK: - BroadcastSampleHandlerDelegate

public protocol BroadcastSampleHandlerDelegate: AnyObject {
    func broadcastSampleHandler(
        _ handler: BroadcastSampleHandler,
        didFinishWithError error: Error
    )
}

// MARK: - BroadcastSampleHandler

/// A class for use in Broadcast Upload Extension on iOS.
public final class BroadcastSampleHandler {
    public weak var delegate: BroadcastSampleHandlerDelegate?
    public var isConnected: Bool { _isConnected.value }

    private let userDefaults: UserDefaults?
    private let videoSender: BroadcastVideoSender
    private let notificationCenter = BroadcastNotificationCenter.default
    private var cancellables = Set<AnyCancellable>()
    private let _isConnected = Synchronized(false)

    // MARK: - Init

    /**
     Creates a new instance of ``BroadcastSampleHandler``
     - Parameters:
        - appGroup: The app group identifier.
        - fileManager: An optional instance of the file manager.
     */
    public convenience init(
        appGroup: String,
        fileManager: FileManager = .default
    ) {
        let filePath = fileManager.broadcastVideoDataPath(appGroup: appGroup)
        let userDefaults = UserDefaults(suiteName: appGroup)
        self.init(
            videoSender: BroadcastVideoSender(
                filePath: filePath,
                fileManager: fileManager
            ),
            userDefaults: userDefaults
        )
    }

    init(
        videoSender: BroadcastVideoSender,
        userDefaults: UserDefaults?
    ) {
        self.videoSender = videoSender
        self.userDefaults = userDefaults
    }

    deinit {
        clean()
    }

    // MARK: - Public

    /// Performs the required actions after starting a live broadcast.
    public func broadcastStarted() {
        // Add some buffer for read/write operation to UserDefaults.
        let timeInterval = TimeInterval(BroadcastScreenCapturer.keepAliveInterval * 5)

        guard
            let date = userDefaults?.broadcastKeepAliveDate,
            date.timeIntervalSinceNow > -timeInterval
        else {
            broadcastFinished()
            onError(.noConnection)
            return
        }

        addNotificationObservers()
        notificationCenter.post(.senderStarted)
    }

    // Performs the required actions after a live broadcast is paused.
    public func broadcastPaused() {
        notificationCenter.post(.senderPaused)
    }

    // Performs the required actions after a live broadcast is resumed.
    public func broadcastResumed() {
        notificationCenter.post(.senderResumed)
    }

    // Performs the required actions after a live broadcast is finished.
    public func broadcastFinished() {
        clean()
        notificationCenter.post(.senderFinished)
    }

    /**
     Processes video and audio data as it becomes available during a live broadcast.
     - Parameters:
        - sampleBuffer: An object containing either audio or video data.
        - sampleBufferType: An object identifying the media type of the sample.
     - Returns: True is the sample buffer was handled, False otherwise.
     */
    @discardableResult
    public func processSampleBuffer(
        _ sampleBuffer: CMSampleBuffer,
        with sampleBufferType: RPSampleBufferType
    ) -> Bool {
        return autoreleasepool {
            guard _isConnected.value else {
                return false
            }

            guard
                sampleBuffer.numSamples == 1,
                sampleBuffer.isValid,
                sampleBuffer.dataReadiness == .ready
            else {
                return false
            }

            switch sampleBufferType {
            case .video:
                return videoSender.send(sampleBuffer)
            case .audioApp, .audioMic:
                return false
            @unknown default:
                return false
            }
        }
    }

    // MARK: - Private

    private func addNotificationObservers() {
        notificationCenter.addObserver(self, for: .receiverStarted) { [weak self] in
            self?._isConnected.setValue(true)
            do {
                let fps = BroadcastFps(value: self?.userDefaults?.broadcastFps)
                try self?.videoSender.start(withFps: fps)
            } catch {
                self?.onError(.noConnection)
            }
        }

        notificationCenter.addObserver(self, for: .receiverFinished) { [weak self] in
            self?.finishWithReason(nil)
        }

        notificationCenter.addObserver(self, for: .callEnded) { [weak self] in
            self?.finishWithReason(.callEnded)
        }

        notificationCenter.addObserver(self, for: .presentationStolen) { [weak self] in
            self?.finishWithReason(.presentationStolen)
        }
    }

    private func clean() {
        videoSender.stop()
        notificationCenter.removeObserver(self)
    }

    private func finishWithReason(_ reason: ScreenCaptureStopReason?) {
        let error: BroadcastError

        switch reason {
        case .none:
            error = .broadcastFinished
        case .callEnded:
            error = .callEnded
        case .presentationStolen:
            error = .presentationStolen
        }

        _isConnected.setValue(false)
        clean()
        onError(error)
    }

    private func onError(_ error: BroadcastError) {
        delegate?.broadcastSampleHandler(self, didFinishWithError: error)
    }
}

#endif
