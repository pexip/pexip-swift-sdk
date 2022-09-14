import Foundation

@frozen
public enum ConferenceSignalingError: LocalizedError, CustomStringConvertible, Hashable {
    case pwdsMissing
    case ufragMissing
    case callNotStarted

    public var description: String {
        switch self {
        case .pwdsMissing:
            return "There are no ICE pwds in the given SDP offer."
        case .ufragMissing:
            return "Ufrag is missing in the given ICE candidate."
        case .callNotStarted:
            return "The operation cannot be performed before starting a call"
        }
    }

    public var errorDescription: String? {
        description
    }
}
