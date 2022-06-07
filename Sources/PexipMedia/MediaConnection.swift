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
        - localVideoTrack: Local camera video track
     */
    func sendMainVideo(localVideoTrack: CameraVideoTrack)

    /**
     Sends video from the given local screen video track (starts screen sharing session).
     */
    func sendPresentationVideo(screenVideoTrack: ScreenVideoTrack) async throws

    /// Stops sending local presentation (stops screen sharing session).
    func stopSendingPresentation() async throws

    @available(*, deprecated, renamed: "startReceivingPresentation")
    /// Creates a remote presentation track and starts receiving remote presentation.
    func startPresentationReceive() throws

    @available(*, deprecated, renamed: "stopReceivingPresentation")
    /// Stops receiving remote presentation.
    func stopPresentationReceive() throws

    /// Creates a remote presentation track and starts receiving remote presentation.
    func startReceivingPresentation() throws

    /// Stops receiving remote presentation.
    func stopReceivingPresentation() throws
}
