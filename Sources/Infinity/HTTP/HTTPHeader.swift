import Foundation

/// A representation of a single HTTP header's name / value pair.
struct HTTPHeader: Hashable, CustomStringConvertible {
    let name: String
    let value: String
    var description: String { "\(name): \(value)" }

    static func userAgent(_ value: String) -> HTTPHeader {
        HTTPHeader(name: "User-Agent", value: value)
    }

    static func contentType(_ value: String) -> HTTPHeader {
        HTTPHeader(name: "Content-Type", value: value)
    }

    // MARK: - Defaults

    /// User-Agent Header
    /// Example: `pexip-ios-sdk/0.0.1`
    public static let defaultUserAgent: HTTPHeader = {
        let bundle = Bundle.main
        let name = bundle.name ?? "pexip-ios-sdk"
        let version = bundle.version ?? "Unknown"
        return .userAgent("\(name)/\(version)")
    }()
}

// MARK: - Private extensions

private extension Bundle {
    var name: String? {
        object(forInfoDictionaryKey: "CFBundleName") as? String
    }
    
    var version: String? {
        object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }
}
