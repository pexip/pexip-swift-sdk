struct IceCandidate: Hashable, Encodable {
    /// Looking for
    static func pwd(from sdp: String) -> String? {
        Regex(".*\\bice-pwd:(.*)")
            .match(sdp)?
            .groupValue(at: 1)
    }

    /// Representation of address in candidate-attribute format as per RFC5245.
    let candidate: String
    /// The media stream identifier tag.
    let mid: String?
    /// The randomly generated username fragment of the ICE credentials.
    let ufrag: String?
    /// The randomly generated password of the ICE credentials.
    let pwd: String?
}

// MARK: - Init

extension IceCandidate {
    init(candidate: String, mid: String?, pwd: String? = nil) {
        self.init(
            candidate: candidate,
            mid: mid,
            ufrag: Regex(".*\\bufrag\\s+(.+?)\\s+.*")
                .match(candidate)?
                .groupValue(at: 1),
            pwd: pwd
        )
    }
}
