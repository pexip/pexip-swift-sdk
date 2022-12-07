import Foundation

/// The object responsible for setting up and controlling a communication session.
public protocol SignalingChannel {
    /// The list of ice servers.
    var iceServers: [IceServer] { get }

    // The call ID (if present)
    var callId: UUID? { get async }

    /**
     Sends a new local SDP.

     - Parameters:
        - callType: The type of the call ("WEBRTC" for a WebRTC call).
        - description: The new local SDP
        - presentationInMain: Controls whether or not the participant sees
                              presentation in the layout mix.

     - Returns: The new SDP answer
     */
    func sendOffer(
        callType: String,
        description: String,
        presentationInMain: Bool
    ) async throws -> String?

    /**
     Sends a new SDP answer.

     - Parameters:
        - description: The new SDP answer
     */
    func sendAnswer(_ description: String) async throws

    /**
     Sends a new ICE candidate if doing trickle ICE.

     - Parameters:
        - candidate: Representation of address in candidate-attribute format as per RFC5245.
        - mid: The media stream identifier tag.
     */
    func addCandidate(_ candidate: String, mid: String?) async throws

    /**
     Sends a sequence of DTMF signals

     - Parameters:
        - signals: The DTMF signals to send
     */
    @discardableResult
    func dtmf(signals: DTMFSignals) async throws -> Bool

    /**
     Mutes or unmutes a participant's video.

     - Parameters:
        - muted: `true` to mute the video, `false` to unmute the video.
     */
    @discardableResult
    func muteVideo(_ muted: Bool) async throws -> Bool

    /**
     Mutes or unmutes a participant's audio.

     - Parameters:
        - muted: `true` to mute the audio, `false` to unmute the audio.
     */
    @discardableResult
    func muteAudio(_ muted: Bool) async throws -> Bool

    /// Requests to take presentation floor.
    @discardableResult
    func takeFloor() async throws -> Bool

    /// Requests to release presentation floor.
    @discardableResult
    func releaseFloor() async throws -> Bool
}
