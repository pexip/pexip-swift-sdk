import Foundation

public struct ConferenceName: RawRepresentable, Hashable {
    public let rawValue: String
    public let alias: String
    public let domain: String

    /// - Parameter rawValue: Conference URI in the form of conference@domain.org
    public init?(rawValue: String) {
        let checkingType = NSTextCheckingResult.CheckingType.link.rawValue
        let detector = try? NSDataDetector(types: checkingType)
        let range = NSRange(rawValue.startIndex..<rawValue.endIndex, in: rawValue)
        let matches = detector?.matches(in: rawValue, options: [], range: range)
        let parts = rawValue.components(separatedBy: "@")

        // Check if our string contains only a single email
        guard let match = matches?.first, matches?.count == 1 else {
            return nil
        }

        guard match.url?.scheme == "mailto", match.range == range else {
            return nil
        }

        guard let alias = parts.first, let domain = parts.last, parts.count == 2 else {
            return nil
        }

        self.rawValue = rawValue
        self.alias = alias
        self.domain = domain
    }
}
