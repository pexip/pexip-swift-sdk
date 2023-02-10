import PexipScreenCapture

/// A local screen media track.
public protocol ScreenMediaTrack: LocalMediaTrack, VideoTrack {
    /**
     Starts the capture.

     - Parameters:
        - videoProfile: The video ``QualityProfile``
     */
    func startCapture(withVideoProfile videoProfile: QualityProfile) async throws

    /**
     Stops screen capture with the given reason.

     - Parameters:
        - reason: An optional reason why screen capture was stopped.
     */
    func stopCapture(reason: ScreenCaptureStopReason?)
}
