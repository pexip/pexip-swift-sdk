
public protocol ScreenVideoTrack: LocalMediaTrack, VideoTrack {
    #if os(macOS)

    func startCapture(
        withConfiguration configuration: ScreenCaptureConfiguration
    ) async throws

    #endif
}
