import WebRTC

final class RTCVideoComponent: VideoComponent {
    private var track: RTCVideoTrack?
    private weak var renderer: RTCVideoRenderer?

    var isEnabled: Bool {
        get { track?.isEnabled ?? false }
        set { track?.isEnabled = newValue }
    }

    init(track: RTCVideoTrack?) {
        self.track = track
    }

    deinit {
        removeCurrentRenderer()
    }

    // MARK: - Internal methods

    func render(to view: VideoView) {
        removeCurrentRenderer()

        let renderer = RTCMTLVideoView(frame: view.frame)
        renderer.translatesAutoresizingMaskIntoConstraints = false
        renderer.videoContentMode = .scaleAspectFit

        view.addSubview(renderer)

        NSLayoutConstraint.activate([
            renderer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            renderer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            renderer.topAnchor.constraint(equalTo: view.topAnchor),
            renderer.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        track?.add(renderer)
        self.renderer = renderer
    }

    func mute(_ isMuted: Bool) async throws {
        isEnabled = isMuted
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
            track?.remove(renderer)
            self.renderer = nil
        }
    }
}
