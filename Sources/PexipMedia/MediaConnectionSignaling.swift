/// The object responsible for setting up and controlling a communication session.
public protocol MediaConnectionSignaling {
    /**
     Sends a new local SDP.
     - Parameters:
        - callType: The type of the call ("WEBRTC" for a WebRTC call).
        - description: The new local SDP
        - presentationInMain: Controls whether or not the participant sees
                              presentation in the layout mix.
     */
    func sendOffer(
        callType: String,
        description: String,
        presentationInMain: Bool
    ) async throws -> String

    /**
     Sends a new ICE candidate if doing trickle ICE.
     - Parameters:
        - sdp: Representation of address in candidate-attribute format as per RFC5245.
        - mid: The media stream identifier tag.
     */
    func addCandidate(sdp: String, mid: String?) async throws

    /**
     Mutes or unmutes a participant's video.
     - Parameters:
        - muted: `true` to mute the video, `false` to unmute the video.
     */
    func muteVideo(_ muted: Bool) async throws

    /**
     Mutes or unmutes a participant's audio.
     - Parameters:
        - muted: `true` to mute the audio, `false` to unmute the audio.
     */
    func muteAudio(_ muted: Bool) async throws

    /// Starts sending local presentation.
    func takeFloor() async throws

    /// Stops sending local presentation.
    func releaseFloor() async throws
}
