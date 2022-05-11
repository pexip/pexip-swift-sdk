import AVFoundation
import Combine

/// Observable object that holds references to main and presentation remote video tracks.
public final class RemoteVideoTracks: ObservableObject {
    /// The main remote video track.
    @Published public var mainTrack: VideoTrack?
    /// The presentation remote video track.
    @Published public var presentationTrack: VideoTrack?

    /**
     Creates a new instance of ``RemoteVideoTracks`` object.
     - Parameters:
        - mainTrack: The main remote video track
        - presentationTrack: The presentation remote video track
     */
    public init(mainTrack: VideoTrack?, presentationTrack: VideoTrack?) {
        self.mainTrack = mainTrack
        self.presentationTrack = presentationTrack
    }
}

/// Media connection between the local computer and a remote peer.
public protocol MediaConnection {
    /// The publisher that publishes state changes.
    var statePublisher: AnyPublisher<MediaConnectionState, Never> { get }

    /// Observable object that holds references to main and presentation remote video tracks.
    var remoteVideoTracks: RemoteVideoTracks { get }

    /// Creates a media session
    func start() async throws

    /// Terminates all media and deallocates resources
    func stop()

    /**
     Sends audio from the given local audio track
     - Parameters:
        - localAudioTrack: Local audio track
     */
    func sendMainAudio(localAudioTrack: LocalAudioTrack)

    /**
     Sends video from the given local video track
     - Parameters:
        - localVideoTrack: Local video track
     */
    func sendMainVideo(localVideoTrack: LocalVideoTrack)

    /// Creates a remote presentation track and starts receiving remote presentation.
    func startPresentationReceive() throws

    /// Stops receiving remote presentation.
    func stopPresentationReceive() throws
}
