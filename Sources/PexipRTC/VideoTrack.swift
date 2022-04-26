import WebRTC

// MARK: - Protocol

#if os(iOS)
import UIKit
public typealias VideoRenderer = UIView
#else
import AppKit
public typealias VideoRenderer = NSView
#endif

public protocol VideoTrack {
    var aspectRatio: CGSize { get }
    func setRenderer(_ view: VideoRenderer, aspectFit: Bool)
}

// MARK: - Implementation

final class DefaultVideoTrack: VideoTrack {
    let aspectRatio: CGSize
    private var rtcTrack: RTCVideoTrack
    private weak var renderer: RTCVideoRenderer?

    // MARK: - Init

    init(rtcTrack: RTCVideoTrack, aspectRatio: CGSize) {
        self.rtcTrack = rtcTrack
        self.aspectRatio = aspectRatio
    }

    deinit {
        removeCurrentRenderer()
    }

    // MARK: - Public

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

    // MARK: - Private methods

    private func removeCurrentRenderer() {
        if let renderer = renderer {
            renderEmptyFrame()
            rtcTrack.remove(renderer)
            self.renderer = nil
        }
    }
}
