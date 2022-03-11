public enum PresentationEvent {
    case started(
        track: VideoTrackProtocol,
        details: PresentationDetails
    )
    case failed
    case stopped
}
