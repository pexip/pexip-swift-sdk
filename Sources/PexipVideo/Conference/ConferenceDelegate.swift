import Combine

// MARK: - Call

public protocol ConferenceCallDelegate: AnyObject {
    func conference(
        _ conference: ConferenceProtocol,
        didReceiveCallEvent event: CallEvent
    )
}

// MARK: - Presentation

public protocol ConferencePresentationDelegate: AnyObject {
    func conference(
        _ conference: ConferenceProtocol,
        didReceivePresentationEvent event: PresentationEvent
    )
}
