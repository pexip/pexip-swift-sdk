public struct MediaConnectionConfig {
    public static let googleStunUrls = [
        "stun:stun.l.google.com:19302",
        "stun:stun1.l.google.com:19302",
        "stun:stun2.l.google.com:19302",
        "stun:stun3.l.google.com:19302",
        "stun:stun4.l.google.com:19302"
    ]
    public static let googleIceServer = IceServer(urls: googleStunUrls)

    /// The object responsible for setting up and controlling a communication session.
    public let signaling: MediaConnectionSignaling

    /// The list of ice servers.
    public let iceServers: [IceServer]

    /// The max bandwidth of a video stream.
    public let bandwidth: Bandwidth

    /// Controls whether or not the participant sees presentation in the layout mix.
    public let presentationInMain: Bool

    /**
     Creates a new instance of ``MediaConnectionConfig``.

     - Parameters:
        - signaling: The object responsible for setting up and controlling
                     a communication session.
        - iceServers: The list of ice servers.
        - bandwidth: The max bandwidth of a video stream.
        - presentationInMain: Controls whether or not the participant sees
                              presentation in the layout mix.
     */
    public init(
        signaling: MediaConnectionSignaling,
        iceServers: [IceServer] = [],
        bandwidth: Bandwidth = .high,
        presentationInMain: Bool = false
    ) {
        self.signaling = signaling

        let iceServers = (signaling.iceServers + iceServers).filter {
            !$0.urls.isEmpty
        }
        self.iceServers = iceServers.isEmpty
            ? [Self.googleIceServer]
            : iceServers

        self.bandwidth = bandwidth
        self.presentationInMain = presentationInMain
    }
}
