import Foundation

/// Representation of the DTMF signals.
public struct DTMFSignals: RawRepresentable, Hashable {
    public static let allowedCharacters = CharacterSet(charactersIn: "0123456789*#ABCD")
    public var rawValue: String

    /**
     Creates a new instance of ``DTMFSignals`` struct.

     - Parameters:
        - rawValue: The DTMF string.
     */
    public init?(rawValue: String) {
        let rawValue = rawValue.trimmingCharacters(in: .whitespaces)

        guard !rawValue.isEmpty else {
            return nil
        }

        guard CharacterSet(
            charactersIn: rawValue
        ).isSubset(of: Self.allowedCharacters) else {
            return nil
        }

        self.rawValue = rawValue
    }
}
