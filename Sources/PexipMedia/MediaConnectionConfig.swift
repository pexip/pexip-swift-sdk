import PexipCore

/// ``MediaConnection`` configuration.
public struct MediaConnectionConfig {
    /// The list of Google STUN urls
    public static let googleStunUrls = [
        "stun:stun.l.google.com:19302",
        "stun:stun1.l.google.com:19302",
        "stun:stun2.l.google.com:19302",
        "stun:stun3.l.google.com:19302",
        "stun:stun4.l.google.com:19302"
    ]
    /// The Google Ice server.
    public static let googleIceServer = IceServer(urls: googleStunUrls)

    /// The object responsible for setting up and controlling a communication session.
    public let signaling: SignalingChannel

    /// The list of ice servers.
    public let iceServers: [IceServer]

    /// The max bandwidth of a video stream.
    public let bandwidth: Bandwidth

    /// Sets whether DSCP is enabled (default is false).
    ///
    /// DSCP (Differentiated Services Code Point) values mark individual packets
    /// and may be beneficial in a variety of networks to improve QoS.
    ///
    /// See [RFC 8837](https://datatracker.ietf.org/doc/html/rfc8837) for more info.
    public let dscp: Bool

    /// Sets whether presentation will be mixed with main video feed.
    public let presentationInMain: Bool

    /**
     Creates a new instance of ``MediaConnectionConfig``.

     - Parameters:
        - signaling: The object responsible for setting up and controlling a communication session.
        - iceServers: The list of ice servers.
        - bandwidth: The max bandwidth of a video stream.
        - dscp: Sets whether DSCP is enabled.
        - presentationInMain: Sets whether presentation will be mixed with main video feed.
     */
    public init(
        signaling: SignalingChannel,
        iceServers: [IceServer] = [],
        bandwidth: Bandwidth = .high,
        dscp: Bool = false,
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
        self.dscp = dscp
        self.presentationInMain = presentationInMain
    }
}
