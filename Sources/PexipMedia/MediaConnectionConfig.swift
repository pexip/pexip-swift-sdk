public struct MediaConnectionConfig {
    public static let googleStunUrls = [
        "stun:stun.l.google.com:19302",
        "stun:stun1.l.google.com:19302",
        "stun:stun2.l.google.com:19302",
        "stun:stun3.l.google.com:19302",
        "stun:stun4.l.google.com:19302"
    ]
    public static let googleIceServer = IceServer(urls: googleStunUrls)

    public let signaling: MediaConnectionSignaling
    public let iceServers: [IceServer]
    public let presentationInMain: Bool

    /**
     - Parameters:
        - signaling: The object responsible for setting up and controlling
                     a communication session.
        - iceServers: The list of ice servers.
        - presentationInMain: Controls whether or not the participant sees
                              presentation in the layout mix.
     */
    public init(
        signaling: MediaConnectionSignaling,
        iceServers: [IceServer] = [],
        presentationInMain: Bool = false
    ) {
        self.signaling = signaling

        let iceServers = iceServers.filter { !$0.urls.isEmpty }
        self.iceServers = iceServers.isEmpty
            ? [Self.googleIceServer]
            : iceServers

        self.presentationInMain = presentationInMain
    }
}
