// MARK: - Call

public enum ConferenceCallEvent {
    case started
    case ended
}

public protocol ConferenceCallDelegate: AnyObject {
    func conference(
        _ conference: ConferenceProtocol,
        didSendCallEvent event: ConferenceCallEvent
    )
}

// MARK: - Remote presentation

public enum ConferencePresentationEvent {
    case started(
        track: VideoTrackProtocol,
        details: PresentationDetails
    )
    case stopped
}

public protocol ConferencePresentationDelegate: AnyObject {
    func conference(
        _ conference: ConferenceProtocol,
        didSendPresentationEvent event: ConferencePresentationEvent
    )
}
