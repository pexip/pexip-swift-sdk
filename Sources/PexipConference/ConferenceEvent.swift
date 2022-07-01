import PexipInfinityClient

/// Conference events
public enum ConferenceEvent {
    /// Conference properties have been updated
    case conferenceUpdate(ConferenceStatus)

    /// Live captions received
    case liveCaptions(LiveCaptions)

    /// Marks the start of a presentation, and includes the information
    /// on which participant is presenting
    case presentationStart(PresentationStartMessage)

    // The presentation has finished
    case presentationStop

    /// The participant is being disconnected from the Pexip side
    case clientDisconnected
}

/// The object that acts as the delegate of the conference.
public protocol ConferenceDelegate: AnyObject {
    /**
     Tells the delegate about a new conference event.
     - Parameters:
        - conference: The conference
        - event: The conference event
     */
    func conference(
        _ conference: Conference,
        didReceiveEvent event: ConferenceEvent
    )
}
