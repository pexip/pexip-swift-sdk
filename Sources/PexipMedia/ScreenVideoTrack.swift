public protocol ScreenVideoTrack: LocalMediaTrack, VideoTrack {
    func startCapture(profile: QualityProfile) async throws
}
