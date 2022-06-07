#if os(iOS)

import CoreMedia
import ReplayKit

public protocol BroadcastSampleHandlerDelegate: AnyObject {
    func broadcastSampleHandler(
        _ handler: BroadcastSampleHandler,
        didFailWithError error: Error?
    )
}

public final class BroadcastSampleHandler {
    public weak var delegate: BroadcastSampleHandlerDelegate?

    private let client: BroadcastClient
    private let notificationCenter = BroadcastNotificationCenter.default
    private let processQueue = DispatchQueue(
        label: "com.pexip.PexipMedia.BroadcastSampleHandler",
        qos: .userInteractive
    )
    private var frame: Int = 0

    // MARK: - Init

    public init(
        appGroup: String,
        fileManager: FileManager = .default
    ) {
        let filePath = fileManager.broadcastSocketPath(appGroup: appGroup)
        self.client = BroadcastClient(filePath: filePath)
        client.delegate = self
    }

    deinit {
        removeNotificationObservers()
    }

    // MARK: - Public

    /// Performs the required actions after starting a live broadcast.
    public func broadcastStarted() {
        frame = 0
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
            frame += 1

            if frame % 3 == 0 {
                processQueue.async { [weak self] in
                    self?.processVideoFrame(from: sampleBuffer)
                }
            }
        case .audioApp, .audioMic:
            return
        @unknown default:
            return
        }
    }

    // MARK: - Private

    private func processVideoFrame(from sampleBuffer: CMSampleBuffer) {
        if let message = BroadcastMessage(sampleBuffer: sampleBuffer) {
            Task {
                await client.send(message: message)
            }
        }
    }

    private func addNotificationObservers() {
        notificationCenter.addObserver(for: .serverStarted) { [weak self] in
            self?.client.start()
        }
    }

    private func removeNotificationObservers() {
        notificationCenter.removeObserver(for: .serverStarted)
    }
}

// MARK: - BroadcastClientDelegate

extension BroadcastSampleHandler: BroadcastClientDelegate {
    func broadcastClient(
        _ client: BroadcastClient,
        didStopWithError error: Error?
    ) {
        delegate?.broadcastSampleHandler(self, didFailWithError: error)
    }
}

#endif
