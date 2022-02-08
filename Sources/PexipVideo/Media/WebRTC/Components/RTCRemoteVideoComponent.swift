import WebRTC

final class RTCRemoteVideoComponent {
    private var videoComponent: RTCVideoComponent?

    // MARK: - Internal methods

    func render(to renderer: RTCVideoRenderer) {
        videoComponent?.render(to: renderer)
    }

    func setTrack(_ track: RTCVideoTrack) {
        videoComponent = RTCVideoComponent(track: track)
    }
}
