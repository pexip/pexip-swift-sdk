import WebRTC

final class RTCVideoComponent {
    private var track: RTCVideoTrack
    private weak var renderer: RTCVideoRenderer?

    var isEnabled: Bool {
        get { track.isEnabled }
        set { track.isEnabled = newValue }
    }

    init(track: RTCVideoTrack) {
        self.track = track
    }

    deinit {
        removeCurrentRenderer()
    }

    // MARK: - Internal methods

    func render(to renderer: RTCVideoRenderer) {
        guard renderer !== self.renderer else {
            return
        }

        removeCurrentRenderer()
        track.add(renderer)
        self.renderer = renderer
    }

    func renderEmptyFrame() {
        renderer?.renderFrame(nil)
    }

    func setTrack(_ track: RTCVideoTrack) {
        self.track = track

        if let renderer = renderer {
            track.add(renderer)
        }
    }

    // MARK: - Private methods

    private func removeCurrentRenderer() {
        if let renderer = renderer {
            renderEmptyFrame()
            track.remove(renderer)
            self.renderer = nil
        }
    }
}
