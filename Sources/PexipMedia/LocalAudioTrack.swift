public protocol LocalAudioTrack: LocalMediaTrack {
    #if os(iOS)
    func speakerOn()
    func speakerOff()
    #endif
}
