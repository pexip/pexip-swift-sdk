public enum PresentationType: String, Encodable {
    case inMix
    case receive
}

/// The object responsible for setting up and controlling a communication session.
public protocol MediaConnectionSignaling {
    func sendOffer(
        callType: String,
        description: String,
        presentationInMain: Bool
    ) async throws -> String

    func addCandidate(sdp: String, mid: String?) async throws
    func muteVideo(_ muted: Bool) async throws
    func muteAudio(_ muted: Bool) async throws
}
