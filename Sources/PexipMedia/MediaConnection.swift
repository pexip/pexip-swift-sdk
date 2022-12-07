import AVFoundation
import Combine
import PexipCore

public typealias DTMFSignals = PexipCore.DTMFSignals

/// Observable object that holds references to main and presentation remote video tracks.
public final class RemoteVideoTracks: ObservableObject {
    /// The main remote video track.
    @Published public private(set) var mainTrack: VideoTrack?
    /// The presentation remote video track.
    @Published public private(set) var presentationTrack: VideoTrack?

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

    public func setMainTrack(_ track: VideoTrack?) {
        Task { @MainActor in
            mainTrack = track
        }
    }

    public func setPresentationTrack(_ track: VideoTrack?) {
        Task { @MainActor in
            presentationTrack = track
        }
    }
}

/// Media connection between the local computer and a remote peer.
public protocol MediaConnection {
    /// The publisher that publishes state changes.
    var statePublisher: AnyPublisher<MediaConnectionState, Never> { get }

    /// Observable object that holds references to main and presentation remote video tracks.
    var remoteVideoTracks: RemoteVideoTracks { get }

    /// Observable object that holds secure check code.
    /// Check algorithm is triggered on each send / receive of an SDP offer / answer.
    var secureCheckCode: SecureCheckCode { get }

    /**
     Sets the given local audio track as the main audio track
     of the media connection and starts sending audio.

     - Parameters:
        - audioTrack: Local audio track
     */
    func setMainAudioTrack(_ audioTrack: LocalAudioTrack?)

    /**
     Sets the given local video track as the main video track
     of the media connection and starts sending video.

     - Parameters:
        - localVideoTrack: Local camera video track
     */
    func setMainVideoTrack(_ videoTrack: CameraVideoTrack?)

    /**
     Sets the given local screen media track as the source for local presentation.

     Call ``ScreenMediaTrack.startCapture`` to start your presentation
     and ``ScreenMediaTrack.stopCapture`` to stop your presentation.

     - Parameters:
        - screenMediaTrack: Local screen media track
     */
    func setScreenMediaTrack(_ screenMediaTrack: ScreenMediaTrack?)

    /// Creates a media session
    func start() async throws

    /// Terminates all media and deallocates resources
    func stop()

    /**
     Handles the incoming offer.
     - Parameters:
        - offer: A remote SDP offer.
     */
    func receiveNewOffer(_ offer: String) async throws

    /**
     Adds new incoming ICE candidate.
     - Parameters:
        - sdp: The SDP string for this candidate
        - mid: The SDP mid for this candidate
     */
    func addCandidate(sdp: String, mid: String?) async throws

    /**
     Adds or removes remote presentation track from the current media connection.

     - Parameters:
        - receive: True to add remote presentation track, False to remove it.
     */
    func receivePresentation(_ receive: Bool) throws

    /**
     Sends a sequence of DTMF signals

     - Parameters:
        - signals: The DTMF signals to send
     */
    @discardableResult
    func dtmf(signals: DTMFSignals) async throws -> Bool
}
