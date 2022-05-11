public protocol LocalVideoTrack: LocalMediaTrack, VideoTrack {
    func startCapture(profile: QualityProfile) async throws
}
