// MARK: - Video

public protocol VideoTrackProtocol: AnyObject {
    var isEnabled: Bool { get set }
    func render(to view: VideoView, aspectFit: Bool)
}

// MARK: - Local video

public protocol LocalVideoTrackProtocol: VideoTrackProtocol {
    func toggleCamera()
}

// MARK: - Audio

public protocol AudioTrackProtocol: AnyObject {
    var isEnabled: Bool { get set }
    func speakerOn()
    func speakerOff()
}
