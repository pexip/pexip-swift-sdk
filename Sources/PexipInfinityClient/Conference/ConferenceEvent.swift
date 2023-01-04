import Foundation

/// All conference-related events.
@frozen
public enum ConferenceEvent: Hashable {
    /// New conference splash screen event received.
    case splashScreen(SplashScreenEvent?)

    /// Conference properties have been updated.
    case conferenceUpdate(ConferenceStatus)

    /// New live captions event received.
    case liveCaptions(LiveCaptions)

    /// A chat message has been broadcast to the conference.
    case messageReceived(ChatMessage)

    /// New SDP offer received
    case newOffer(NewOfferMessage)

    /// Remote SDP updated
    case updateSdp(UpdateSdpMessage)

    /// New ICE candidate received
    case newCandidate(IceCandidate)

    /// Marks the start of a presentation,
    /// and includes the information on which participant is presenting.
    case presentationStart(PresentationStartEvent)

    /// The presentation has finished.
    case presentationStop

    /// Sending of the complete participant list started.
    case participantSyncBegin

    /// Sending of the complete participant list ended.
    case participantSyncEnd

    /// A new participant has joined the conference.
    case participantCreate(Participant)

    /// A participant's properties have changed.
    case participantUpdate(Participant)

    /// A participant has left the conference.
    case participantDelete(ParticipantDeleteEvent)

    /// Another peer disconnected from the direct media call.
    case peerDisconnected

    /// The participant has been transfered to another call.
    case refer(ReferEvent)

    /// Sent when a child call has been disconnected.
    case callDisconnected(CallDisconnectEvent)

    /// Sent when the participant is being disconnected from the Pexip side.
    case clientDisconnected(ClientDisconnectEvent)

    enum Name: String {
        case splashScreen = "splash_screen"
        case conferenceUpdate = "conference_update"
        case liveCaptions = "live_captions"
        case messageReceived = "message_received"
        case newOffer = "new_offer"
        case updateSdp = "update_sdp"
        case newCandidate = "new_candidate"
        case presentationStart = "presentation_start"
        case presentationStop = "presentation_stop"
        case participantSyncBegin = "participant_sync_begin"
        case participantSyncEnd = "participant_sync_end"
        case participantCreate = "participant_create"
        case participantUpdate = "participant_update"
        case participantDelete = "participant_delete"
        case peerDisconnected = "peer_disconnect"
        case refer
        case callDisconnected = "call_disconnected"
        case clientDisconnected = "disconnect"
    }
}
