import Combine

enum MediaConnectionEvent {
    case connected
    case disconnected
    case closed
    case failed
    case newIceCandidate(IceCandidate)
}

protocol MediaConnection {
    typealias SessionDescription = String

    var audioTrack: LocalAudioTrackProtocol? { get }
    var localVideoTrack: LocalVideoTrackProtocol? { get }
    var remoteVideoTrack: VideoTrackProtocol? { get }
    var eventPublisher: AnyPublisher<MediaConnectionEvent, Never> { get }

    func createOffer() async throws -> SessionDescription
    func setRemoteDescription(_ sdp: SessionDescription) async throws
    func close()
}
