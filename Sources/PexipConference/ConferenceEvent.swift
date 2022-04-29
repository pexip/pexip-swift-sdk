import PexipInfinityClient

public enum ConferenceEvent {
    case presentationStart(PresentationStartMessage)
    case presentationStop
    case clientDisconnected
}

public protocol ConferenceDelegate: AnyObject {
    func conference(
        _ conference: Conference,
        didReceiveEvent event: ConferenceEvent
    )
}
