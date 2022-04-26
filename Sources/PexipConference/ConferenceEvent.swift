import PexipInfinityClient

public enum ConferenceEvent {
    case presentationStarted(PresentationStartMessage)
    case presentationStopped
}

public protocol ConferenceDelegate: AnyObject {
    func conference(
        _ conference: Conference,
        didReceiveEvent event: ConferenceEvent
    )
}
