import WebRTC

final class WebRTCVideoTrack: VideoTrackProtocol {
    private var track: RTCVideoTrack?
    private weak var renderer: RTCVideoRenderer?

    // MARK: - Init

    init(track: RTCVideoTrack?) {
        self.track = track
    }

    deinit {
        removeCurrentRenderer()
    }

    // MARK: - Internal

    var isEnabled: Bool {
        track?.isEnabled ?? false
    }

    func setEnabled(_ enabled: Bool) {
        track?.isEnabled = enabled
    }

    func render(to view: VideoView, aspectFit: Bool) {
        removeCurrentRenderer()

        let renderer = RTCMTLVideoView(frame: view.frame)
        renderer.translatesAutoresizingMaskIntoConstraints = false
        renderer.videoContentMode = aspectFit ? .scaleAspectFit : .scaleAspectFill

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
