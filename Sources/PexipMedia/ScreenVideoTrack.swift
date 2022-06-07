
public protocol ScreenVideoTrack: LocalMediaTrack, VideoTrack {
    #if os(iOS)

    func startCapture(profile: QualityProfile) throws

    #else

    func startCapture(
        withConfiguration configuration: ScreenCaptureConfiguration
    ) async throws

    #endif
}
