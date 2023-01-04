import Foundation

/// Conference-related events important for the consumer of the SDK.
@frozen
public enum ConferenceClientEvent: Hashable {
    /// New conference splash screen event received.
    case splashScreen(SplashScreen?)

    /// Conference properties have been updated.
    case conferenceUpdate(ConferenceStatus)

    /// New live captions event received.
    case liveCaptions(LiveCaptions)

    /// Marks the start of a presentation,
    /// and includes the information on which participant is presenting.
    case presentationStart(PresentationStartEvent)

    /// The presentation has finished.
    case presentationStop

    /// Another peer disconnected from the direct media call.
    case peerDisconnected

    /// The participant has been transfered to another call.
    case refer(ReferEvent)

    /// Sent when a child call has been disconnected.
    case callDisconnected(CallDisconnectEvent)

    /// Sent when the participant is being disconnected from the Pexip side.
    case clientDisconnected(ClientDisconnectEvent)

    /// Unhandled error occured during the conference call.
    case failure(FailureEvent)
}
