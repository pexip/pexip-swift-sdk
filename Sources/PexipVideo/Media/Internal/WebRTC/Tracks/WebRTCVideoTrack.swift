import WebRTC

final class WebRTCVideoTrack: VideoTrackProtocol {
    let aspectRatio: CGSize
    private var track: RTCVideoTrack?
    private weak var renderer: RTCVideoRenderer?

    // MARK: - Init

    init(track: RTCVideoTrack?, aspectRatio: CGSize) {
        self.track = track
        self.aspectRatio = aspectRatio
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

    func setRenderer(_ view: VideoView, aspectFit: Bool) {
        removeCurrentRenderer()

        #if os(iOS)
        let renderer = RTCMTLVideoView(frame: view.frame)
        renderer.videoContentMode = aspectFit ? .scaleAspectFit : .scaleAspectFill
        #else
        let renderer = RTCMTLNSVideoView(frame: view.frame)
        renderer.wantsLayer = true
        #endif
        renderer.translatesAutoresizingMaskIntoConstraints = false

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
