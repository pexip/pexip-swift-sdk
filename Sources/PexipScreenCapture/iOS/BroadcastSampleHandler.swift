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

public final class BroadcastSampleHandler {
    public weak var delegate: BroadcastSampleHandlerDelegate?

    let fps: UInt
    private let client: BroadcastClient
    private let messageLoop: BroadcastMessageLoop
    private let notificationCenter = BroadcastNotificationCenter.default
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    /**
     Creates a new instance of ``BroadcastSampleHandler``
     - Parameters:
        - appGroup: The app group identifier.
        - filemanager: An optional instance of the file manager.
     */
    public convenience init(
        appGroup: String,
        fileManager: FileManager = .default
    ) {
        let filePath = fileManager.broadcastSocketPath(appGroup: appGroup)
        let client = BroadcastClient(filePath: filePath)
        let userDefaults = UserDefaults(suiteName: appGroup)
        /// The broadcast extension has hard memory limit of 50MB.
        /// Use lower frame rate to reduce the memory load.
        let fps = min(userDefaults?.broadcastFps ?? 15, 15)
        self.init(client: client, fps: fps)
    }

    init(client: BroadcastClient, fps: UInt) {
        self.client = client
        self.fps = fps
        messageLoop = BroadcastMessageLoop(fps: fps)

        client.sink { [weak self] event in
            guard let self = self else { return }

            switch event {
            case .connect:
                break
            case .stop(let error):
                self.messageLoop.stop()

                let error = BroadcastError.broadcastFinished(error: error)
                self.delegate?.broadcastSampleHandler(self, didFinishWithError: error)
            }
        }.store(in: &cancellables)

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
     - Returns: True is the sample buffer was handled, False otherwise.
     */
    @discardableResult
    public func processSampleBuffer(
        _ sampleBuffer: CMSampleBuffer,
        with sampleBufferType: RPSampleBufferType
    ) -> Bool {
        guard client.isConnected else {
            return false
        }

        switch sampleBufferType {
        case .video:
            messageLoop.addSampleBuffer(sampleBuffer)
            return true
        case .audioApp, .audioMic:
            return false
        @unknown default:
            return false
        }
    }

    // MARK: - Private

    private func addNotificationObservers() {
        notificationCenter.addObserver(self, for: .serverStarted) { [weak self] in
            self?.client.start()
            self?.messageLoop.start()
        }
    }

    private func removeNotificationObservers() {
        notificationCenter.removeObserver(self)
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

#endif
