#if os(iOS)

import CoreVideo
import Combine
import ReplayKit

/// A capturer that captures the screen content from Broadcast Upload Extension on iOS.
public final class BroadcastScreenCapturer: ScreenMediaCapturer {
    public weak var delegate: ScreenMediaCapturerDelegate?

    private let filePath: String
    private let fileManager: FileManager
    private let broadcastUploadExtension: String
    private let notificationCenter = BroadcastNotificationCenter.default
    private let userDefaults: UserDefaults?
    private var server: BroadcastServer?
    private let isCapturing = Synchronized(false)
    private let processingQueue = DispatchQueue(
        label: "com.pexip.PexipMedia.BroadcastScreenCapturer",
        qos: .userInteractive
    )
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    /**
     Creates a new instance of ``BroadcastScreenCapturer``
     - Parameters:
        - appGroup: The app group identifier
        - broadcastUploadExtension: Bundle identifier of your broadcast upload extension
        - fileManager: An optional instance of the file manager
     */
    public init(
        appGroup: String,
        broadcastUploadExtension: String,
        fileManager: FileManager = .default
    ) {
        self.filePath = fileManager.broadcastSocketPath(appGroup: appGroup)
        self.fileManager = fileManager
        self.broadcastUploadExtension = broadcastUploadExtension
        self.userDefaults = UserDefaults(suiteName: appGroup)
    }

    deinit {
        try? stopCapture()
    }

    // MARK: - Internal

    /**
     Starts the screen capture with the given video quality profile.

     - Parameters:
        - videoProfile: The video ``QualityProfile``
     */
    public func startCapture(
        atFps fps: UInt,
        outputDimensions: CMVideoDimensions
    ) async throws {
        guard !isCapturing.value else {
            return
        }

        addNotificationObservers()
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

    /// Stops the screen capture.
    public func stopCapture() throws {
        guard isCapturing.value else {
            return
        }

        clean()
        try server?.stop()
        server = nil
    }

    // MARK: - Private

    private func addNotificationObservers() {
        notificationCenter.addObserver(self, for: .broadcastStarted) { [weak self] in
            guard let self = self else {
                return
            }

            do {
                self.server = try BroadcastServer(
                    filePath: self.filePath,
                    fileManager: self.fileManager
                )
                self.subscribeToEvents(from: self.server!)
                self.isCapturing.mutate { $0 = true }
                try self.server?.start()
            } catch {
                if self.isCapturing.value {
                    self.clean()
                    self.onStop(error: error)
                }
            }
        }

        notificationCenter.addObserver(self, for: .broadcastFinished) { [weak self] in
            guard let self = self, self.isCapturing.value else {
                return
            }

            var stopError: Error?

            do {
                try self.stopCapture()
            } catch {
                stopError = error
            }

            self.onStop(error: stopError)
        }
    }

    private func removeNotificationObservers() {
        notificationCenter.removeObserver(self)
    }

    private func subscribeToEvents(from server: BroadcastServer) {
        server.sink { [weak self] httpEvent in
            guard let self = self else { return }

            switch httpEvent {
            case .start:
                self.notificationCenter.post(.serverStarted)
            case .message(let message):
                self.processingQueue.async { [weak self] in
                    self?.processMessage(message)
                }
            case .stop(let error):
                if self.isCapturing.value {
                    self.clean()
                    self.onStop(error: error)
                }
            }
        }.store(in: &self.cancellables)
    }

    private func processMessage(_ message: BroadcastMessage) {
        let displayTimeNs = message.header.displayTimeNs

        guard let pixelBuffer = CVPixelBuffer.pixelBuffer(
            fromData: message.body,
            width: Int(message.header.videoWidth),
            height: Int(message.header.videoHeight),
            pixelFormat: message.header.pixelFormat
        ) else {
            return
        }

        let videoFrame = VideoFrame(
            pixelBuffer: pixelBuffer,
            contentRect: CGRect(
                x: 0,
                y: 0,
                width: Int(pixelBuffer.width),
                height: Int(pixelBuffer.height)
            ),
            orientation: .init(rawValue: message.header.videoOrientation) ?? .up,
            displayTimeNs: displayTimeNs
        )

        onCapture(videoFrame: videoFrame)
    }

    private func clean() {
        isCapturing.mutate { $0 = false }
        removeNotificationObservers()
        userDefaults?.broadcastFps = nil
    }

    private func onStop(error: Error?) {
        delegate?.screenMediaCapturer(self, didStopWithError: error)
    }

    private func onCapture(videoFrame: VideoFrame) {
        delegate?.screenMediaCapturer(self, didCaptureVideoFrame: videoFrame)
    }
}

#endif
