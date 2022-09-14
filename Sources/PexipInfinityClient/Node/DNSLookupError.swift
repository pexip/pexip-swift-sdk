import Foundation

@frozen
public enum DNSLookupError: LocalizedError, CustomStringConvertible, Hashable {
    case timeout
    case lookupFailed(code: Int32)
    case responseNotSecuredWithDNSSEC
    case invalidSRVRecordData
    case invalidARecordData

    public var description: String {
        switch self {
        case .timeout:
            return "DNS lookup timeout"
        case .lookupFailed(let code):
            return "DNS lookup failed with error, code: \(code)"
        case .responseNotSecuredWithDNSSEC:
            return "DNS lookup response is not secured with DNSSEC"
        case .invalidSRVRecordData:
            return "Invalid SRV record data received"
        case .invalidARecordData:
            return "Invalid A record data received"
        }
    }

    public var errorDescription: String? {
        description
    }
}
