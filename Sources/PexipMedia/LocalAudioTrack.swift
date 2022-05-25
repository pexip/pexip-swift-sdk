public protocol LocalAudioTrack: LocalMediaTrack {
    /// Starts the capture
    func startCapture() async throws

    #if os(iOS)
    func speakerOn()
    func speakerOff()
    #endif
}
