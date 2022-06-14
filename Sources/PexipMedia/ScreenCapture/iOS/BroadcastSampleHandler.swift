#if os(iOS)

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

public final class BroadcastSampleHandler {
    public weak var delegate: BroadcastSampleHandlerDelegate?

    private let client: BroadcastClient
    private let messageLoop: BroadcastMessageLoop
    private let notificationCenter = BroadcastNotificationCenter.default

    // MARK: - Init

    public init(
        appGroup: String,
        fileManager: FileManager = .default
    ) {
        let filePath = fileManager.broadcastSocketPath(appGroup: appGroup)
        client = BroadcastClient(filePath: filePath)

        let userDefaults = UserDefaults(suiteName: appGroup)
        /// The broadcast extension has hard memory limit of 50MB.
        /// Use lower frame rate to reduce the memory load.
        let fps = min(userDefaults?.broadcastFps ?? 15, 15)
        messageLoop = BroadcastMessageLoop(fps: fps)

        client.delegate = self
        messageLoop.delegate = self
    }

    deinit {
        removeNotificationObservers()
    }

    // MARK: - Public

    /// Performs the required actions after starting a live broadcast.
    public func broadcastStarted() {
        addNotificationObservers()
        notificationCenter.post(.broadcastStarted)
    }

    // Performs the required actions after a live broadcast is paused.
    public func broadcastPaused() {
        notificationCenter.post(.broadcastPaused)
    }

    // Performs the required actions after a live broadcast is resumed.
    public func broadcastResumed() {
        notificationCenter.post(.broadcastResumed)
    }

    // Performs the required actions after a live broadcast is finished.
    public func broadcastFinished() {
        removeNotificationObservers()
        notificationCenter.post(.broadcastFinished)
        messageLoop.stop()
        client.stop()
    }

    /**
     Processes video and audio data as it becomes available during a live broadcast.
     - Parameters:
        - sampleBuffer: An object containing either audio or video data.
        - sampleBufferType: An object identifying the media type of the sample.
     */
    public func processSampleBuffer(
        _ sampleBuffer: CMSampleBuffer,
        with sampleBufferType: RPSampleBufferType
    ) {
        guard client.isConnected else {
            return
        }

        switch sampleBufferType {
        case .video:
            messageLoop.addSampleBuffer(sampleBuffer)
        case .audioApp, .audioMic:
            return
        @unknown default:
            return
        }
    }

    // MARK: - Private

    private func addNotificationObservers() {
        notificationCenter.addObserver(for: .serverStarted) { [weak self] in
            self?.client.start()
            self?.messageLoop.start()
        }
    }

    private func removeNotificationObservers() {
        notificationCenter.removeObserver(for: .serverStarted)
    }
}

// MARK: - BroadcastMessageLoopDelegate

extension BroadcastSampleHandler: BroadcastMessageLoopDelegate {
    func broadcastMessageLoop(
        _ messageLoop: BroadcastMessageLoop,
        didPrepareMessage message: BroadcastMessage
    ) {
        Task {
            await client.send(message: message)
        }
    }
}

// MARK: - BroadcastClientDelegate

extension BroadcastSampleHandler: BroadcastClientDelegate {
    func broadcastClient(
        _ client: BroadcastClient,
        didStopWithError error: Error?
    ) {
        let error = BroadcastError.broadcastFinished(error: error)
        delegate?.broadcastSampleHandler(self, didFinishWithError: error)
    }
}

#endif
