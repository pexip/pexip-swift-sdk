#if os(iOS)

import CoreVideo
import Combine
import PexipUtils
import ReplayKit

/// A video capturer that captures the screen content as a video stream.
public final class BroadcastScreenVideoCapturer: ScreenVideoCapturer {
    public weak var delegate: ScreenVideoCapturerDelegate?

    private let filePath: String
    private let fileManager: FileManager
    private let broadcastUploadExtension: String
    private let notificationCenter = BroadcastNotificationCenter.default
    private let userDefaults: UserDefaults?
    private var server: BroadcastServer?
    private var startTimeNs: UInt64?
    private let isCapturing = Synchronized(false)
    private let processingQueue = DispatchQueue(
        label: "com.pexip.PexipMedia.ScreenVideoCapturer",
        qos: .userInteractive
    )
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

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

    public func startCapture(withFps fps: UInt) async throws {
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
        server.sink { [weak self] event in
            guard let self = self else { return }

            switch event {
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
        startTimeNs = startTimeNs ?? displayTimeNs

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
            orientation: .init(rawValue: message.header.videoOrientation) ?? .up,
            displayTimeNs: displayTimeNs,
            elapsedTimeNs: displayTimeNs - startTimeNs!
        )

        onCapture(videoFrame: videoFrame)
    }

    private func clean() {
        isCapturing.mutate { $0 = false }
        removeNotificationObservers()
        startTimeNs = nil
        userDefaults?.broadcastFps = nil
    }

    private func onStop(error: Error?) {
        delegate?.screenVideoCapturer(self, didStopWithError: error)
    }

    private func onCapture(videoFrame: VideoFrame) {
        delegate?.screenVideoCapturer(self, didCaptureVideoFrame: videoFrame)
    }
}

#endif
