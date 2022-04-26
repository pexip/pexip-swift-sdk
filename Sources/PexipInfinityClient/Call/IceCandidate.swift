public struct IceCandidate: Hashable, Encodable {
    /// Representation of address in candidate-attribute format as per RFC5245.
    public let candidate: String
    /// The media stream identifier tag.
    public let mid: String?
    /// The randomly generated username fragment of the ICE credentials.
    public let ufrag: String?
    /// The randomly generated password of the ICE credentials.
    public let pwd: String?

    // MARK: - Init

    public init(candidate: String, mid: String?, ufrag: String?, pwd: String?) {
        self.candidate = candidate
        self.mid = mid
        self.ufrag = ufrag
        self.pwd = pwd
    }
}
