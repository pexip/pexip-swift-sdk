import Foundation

struct ConferenceURI: RawRepresentable, Hashable {
    let rawValue: String
    let alias: String
    let host: String
    
    init?(rawValue: String) {
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
        
        guard let alias = parts.first, let host = parts.last, parts.count == 2 else {
            return nil
        }

        self.rawValue = rawValue
        self.alias = alias
        self.host = host
    }
}
