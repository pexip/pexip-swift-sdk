#if os(iOS)

import CoreVideo
import Combine
import ReplayKit

// MARK: - ScreenVideoCapturerDelegate

public protocol ScreenVideoCapturerDelegate: AnyObject {
    func screenVideoCapturer(
        _ capturer: ScreenVideoCapturer,
        didCaptureVideoFrame frame: VideoFrame
    )

    func screenVideoCapturer(
        _ capturer: ScreenVideoCapturer,
        didStopWithError error: Error?
    )
}

/// A video capturer that captures the screen content as a video stream.
public final class ScreenVideoCapturer {
    public weak var delegate: ScreenVideoCapturerDelegate?
    public var publisher: AnyPublisher<VideoFrame.Status, Never> {
        subject.eraseToAnyPublisher()
    }

    private let filePath: String
    private let broadcastUploadExtension: String
    private let notificationCenter = BroadcastNotificationCenter.default
    private let subject = PassthroughSubject<VideoFrame.Status, Never>()
    private var server: BroadcastServer?
    private var startTimeNs: UInt64?
    private let processQueue = DispatchQueue(
        label: "com.pexip.PexipMedia.ScreenVideoCapturer",
        qos: .userInteractive
    )

    // MARK: - Init

    public init(
        appGroup: String,
        broadcastUploadExtension: String,
        fileManager: FileManager = .default
    ) {
        self.filePath = fileManager.broadcastSocketPath(appGroup: appGroup)
        self.broadcastUploadExtension = broadcastUploadExtension
    }

    deinit {
        try? stopCapture()
    }

    // MARK: - Internal

    public func startCapture() throws {
        addNotificationObservers()

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
        clean()
        try server?.stop()
    }

    // MARK: - Private

    private func addNotificationObservers() {
        notificationCenter.addObserver(for: .broadcastStarted) { [weak self] in
            guard let self = self else {
                return
            }

            do {
                self.server = try BroadcastServer(path: self.filePath)
                self.server?.delegate = self
                try self.server?.start()
            } catch {
                self.clean()
                self.onStop(error: error)
            }
        }

        notificationCenter.addObserver(for: .broadcastFinished) { [weak self] in
            var stopError: Error?

            do {
                try self?.stopCapture()
            } catch {
                stopError = error
            }

            self?.clean()
            self?.onStop(error: stopError)
        }
    }

    private func removeNotificationObservers() {
        notificationCenter.removeObserver(for: .broadcastStarted)
        notificationCenter.removeObserver(for: .broadcastFinished)
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
        removeNotificationObservers()
        startTimeNs = nil
    }

    private func onStop(error: Error?) {
        delegate?.screenVideoCapturer(self, didStopWithError: error)
        subject.send(.stopped)
    }

    private func onCapture(videoFrame: VideoFrame) {
        delegate?.screenVideoCapturer(self, didCaptureVideoFrame: videoFrame)
        subject.send(.complete(videoFrame))
    }
}

// MARK: - BroadcastServerDelegate

extension ScreenVideoCapturer: BroadcastServerDelegate {
    func broadcastServerDidStart(_ server: BroadcastServer) {
        notificationCenter.post(.serverStarted)
    }

    func broadcastServer(
        _ server: BroadcastServer,
        didReceiveMessage message: BroadcastMessage
    ) {
        processQueue.async { [weak self] in
            self?.processMessage(message)
        }
    }

    func broadcastServer(
        _ server: BroadcastServer,
        didStopWithError error: Error?
    ) {
        clean()
        onStop(error: error)
    }
}

#endif
