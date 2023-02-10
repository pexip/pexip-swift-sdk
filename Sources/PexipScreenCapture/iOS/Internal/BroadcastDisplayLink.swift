#if os(iOS)

import QuartzCore

final class BroadcastDisplayLink {
    var timestamp: Double? {
        displayLink?.timestamp
    }

    private var displayLink: CADisplayLink?
    private var handler: (() -> Void)?

    // MARK: - Init

    init(fps: BroadcastFps, handler: (() -> Void)?) {
        self.handler = handler

        displayLink = CADisplayLink(
            target: self,
            selector: #selector(onDisplayLink)
        )
        displayLink?.preferredFramesPerSecond = Int(fps.value)
        displayLink?.add(to: .current, forMode: .default)
    }

    // MARK: - Internal

    func invalidate() {
        displayLink?.isPaused = true
        displayLink?.remove(from: .current, forMode: .default)
        displayLink?.invalidate()
        displayLink = nil
    }

    // MARK: - Private

    @objc
    private func onDisplayLink() {
        handler?()
    }
}

#endif
