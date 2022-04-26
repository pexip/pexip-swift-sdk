public enum PresentationType: String, Encodable {
    case inMix
    case receive
}

public protocol MediaConnectionSignaling {
    func sendOffer(
        callType: String,
        description: String,
        presentationType: PresentationType?
    ) async throws -> String

    func addCandidate(sdp: String, mid: String?) async throws
    func startMedia() async throws
    func muteVideo(_ muted: Bool) async throws
    func muteAudio(_ muted: Bool) async throws
}
