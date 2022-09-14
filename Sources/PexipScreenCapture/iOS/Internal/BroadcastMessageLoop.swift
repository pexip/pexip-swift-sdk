#if os(iOS)

import Foundation
import CoreMedia
import ReplayKit

// MARK: - BroadcastMessageLoopDelegate

protocol BroadcastMessageLoopDelegate: AnyObject {
    func broadcastMessageLoop(
        _ messageLoop: BroadcastMessageLoop,
        didPrepareMessage message: BroadcastMessage
    )
}

// MARK: - BroadcastMessageLoop

final class BroadcastMessageLoop {
    let fps: UInt
    weak var delegate: BroadcastMessageLoopDelegate?
    var isRunning: Bool { displayLink != nil }

    private let processingQueue = DispatchQueue(
        label: "com.pexip.PexipMedia.BroadcastMessageLoop",
        qos: .userInteractive
    )
    private var displayLink: CADisplayLink?
    private var lastSampleBuffer: CMSampleBuffer?

    // MARK: - Init

    init(fps: UInt) {
        self.fps = fps
    }

    deinit {
        stop()
    }

    // MARK: - Internal

    @discardableResult
    func start() -> Bool {
        guard displayLink == nil else {
            return false
        }

        let displayLink = CADisplayLink(
            target: self,
            selector: #selector(onDisplayLink)
        )
        displayLink.preferredFramesPerSecond = Int(fps)
        displayLink.add(to: .current, forMode: .default)
        self.displayLink = displayLink

        return true
    }

    func stop() {
        displayLink?.isPaused = true
        displayLink?.invalidate()
        displayLink = nil
    }

    func addSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        processingQueue.async { [weak self] in
            self?.lastSampleBuffer = sampleBuffer
        }
    }

    // MARK: - Private

    @objc
    private func onDisplayLink() {
        processingQueue.async { [weak self] in
            self?.prepareMessage()
        }
    }

    private func prepareMessage() {
        guard let displayLink else {
            return
        }

        guard let lastSampleBuffer else {
            return
        }

        let displayTimeNs = UInt64(
            llround(displayLink.timestamp * Float64(NSEC_PER_SEC))
        )

        guard let message = BroadcastMessage(
            sampleBuffer: lastSampleBuffer,
            displayTimeNs: displayTimeNs
        ) else {
            return
        }

        delegate?.broadcastMessageLoop(self, didPrepareMessage: message)
    }
}

#endif
