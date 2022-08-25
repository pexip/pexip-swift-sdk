import PexipInfinityClient

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
