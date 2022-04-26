public enum PresentationType: String, Encodable {
    case inMix
    case receive
}

public protocol MediaConnectionSignaling {
    func onOffer(
        callType: String,
        description: String,
        presentationType: PresentationType?
    ) async throws -> String

    func onCandidate(candidate: String, mid: String?) async throws
    func onConnected() async throws
}
