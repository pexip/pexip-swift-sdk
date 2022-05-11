import AVFoundation

public enum MediaCapturePermissionError: LocalizedError,
                                         CustomStringConvertible,
                                         CaseIterable {
    case restricted
    case denied

    public var description: String {
        switch self {
        case .restricted:
            return "The user can't grant access due to restrictions"
        case .denied:
            return "The user has previously denied access"
        }
    }

    public var errorDescription: String? {
        description
    }

    public init?(status: AVAuthorizationStatus) {
        switch status {
        case .notDetermined, .authorized:
            return nil
        case .restricted:
            self = .restricted
        case .denied:
            self = .denied
        @unknown default:
            return nil
        }
    }
}
