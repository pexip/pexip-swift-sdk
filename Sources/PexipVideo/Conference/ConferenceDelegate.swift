// MARK: - Call

public protocol ConferenceCallDelegate: AnyObject {
    func conferenceDidDisconnect(_ conference: ConferenceProtocol)
}

public enum ConferenceCallEvent {
    case disconnected
}

// MARK: - Media

public protocol ConferenceMediaDelegate: AnyObject {
    func conferenceDidStartMedia(_ conference: ConferenceProtocol)
    func conferenceDidEndMedia(_ conference: ConferenceProtocol)
}

public enum ConferenceMediaEvent {
    case started
    case ended
}
