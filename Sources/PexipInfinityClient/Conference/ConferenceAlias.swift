import Foundation

public struct ConferenceAlias: Hashable {
    public let uri: String
    public let alias: String
    public let host: String

    // MARK: - Init

    /// - Parameter uri: Conference URI in the form of conference@example.com
    public init?(uri: String) {
        let parts = uri.components(separatedBy: "@")

        guard let alias = parts.first, let host = parts.last, parts.count == 2 else {
            return nil
        }

        self.init(alias: alias, host: host)
    }

    /**
     - Parameters:
        - alias: Conference alias
        - host: Conference host in the form of "example.com"
     */
    public init?(alias: String, host: String) {
        let uri = "\(alias)@\(host)"
        let checkingType = NSTextCheckingResult.CheckingType.link.rawValue
        let detector = try? NSDataDetector(types: checkingType)
        let range = NSRange(uri.startIndex..<uri.endIndex, in: uri)
        let matches = detector?.matches(in: uri, options: [], range: range)

        // Check if our string contains only a single email
        guard let match = matches?.first, matches?.count == 1 else {
            return nil
        }

        guard match.url?.scheme == "mailto", match.range == range else {
            return nil
        }

        self.uri = uri
        self.alias = alias
        self.host = host
    }
}
