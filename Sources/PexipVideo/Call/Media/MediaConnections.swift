import Combine

enum CallConnectionEvent {
    case connected
    case disconnected
    case failed
    case newIceCandidate(IceCandidate)
}

protocol CallConnection {
    typealias SessionDescription = String

    var audioTrack: AudioTrackProtocol? { get }
    var localVideoTrack: LocalVideoTrackProtocol? { get }
    var remoteVideoTrack: VideoTrackProtocol? { get }
    var eventPublisher: AnyPublisher<CallConnectionEvent, Never> { get }

    func createOffer() async throws -> SessionDescription
    func setRemoteDescription(_ sdp: SessionDescription) async throws
    func close()
}

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
