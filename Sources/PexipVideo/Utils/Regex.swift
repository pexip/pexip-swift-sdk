import Foundation

struct Regex {
    let pattern: String

    init(_ pattern: String) {
        self.pattern = pattern
    }

    func matchEntire(_ string: String) -> Match? {
        let range = NSRange(location: 0, length: string.utf16.count)
        let regex = try? NSRegularExpression(
            pattern: pattern,
            options: .caseInsensitive
        )
        let result = regex?.firstMatch(in: string, options: [], range: range)
        return result.map { Match(string: string, result: $0) }
    }
}

// MARK: - Match

extension Regex {
    struct Match {
        let string: String
        let result: NSTextCheckingResult

        func groupValue(at index: Int) -> String? {
            guard index >= 0 && index < result.numberOfRanges else {
                return nil
            }
            guard let range = Range(result.range(at: index), in: string) else {
                return nil
            }
            return String(string[range])
        }
    }
}
