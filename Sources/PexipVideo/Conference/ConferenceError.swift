public enum ConferenceError: LocalizedError, CustomStringConvertible {
    case cannotJoinActiveConference
    case cannotLeaveInactiveConference

    public var description: String {
        switch self {
        case .cannotJoinActiveConference:
            return "Cannot join already active conference"
        case .cannotLeaveInactiveConference:
            return "Cannot leave already inactive conference"
        }
    }
}
