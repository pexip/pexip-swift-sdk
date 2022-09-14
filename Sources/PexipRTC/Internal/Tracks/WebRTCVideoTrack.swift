import WebRTC
import PexipMedia

class WebRTCVideoTrack: VideoTrack {
    let rtcTrack: RTCVideoTrack
    private weak var renderer: RTCVideoRenderer?

    // MARK: - Init

    init(rtcTrack: RTCVideoTrack) {
        self.rtcTrack = rtcTrack
    }

    deinit {
        removeCurrentRenderer()
    }

    // MARK: - VideoTrack

    func setRenderer(_ view: VideoRenderer, aspectFit: Bool) {
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

        rtcTrack.add(renderer)
        self.renderer = renderer
    }

    // MARK: - Internal

    var isEnabled: Bool {
        get {
            rtcTrack.isEnabled
        }
        set {
            rtcTrack.isEnabled = newValue
        }
    }

    func renderEmptyFrame() {
        renderer?.renderFrame(nil)
    }

    // MARK: - Private

    private func removeCurrentRenderer() {
        if let renderer {
            renderEmptyFrame()
            rtcTrack.remove(renderer)
            self.renderer = nil
        }
    }
}
