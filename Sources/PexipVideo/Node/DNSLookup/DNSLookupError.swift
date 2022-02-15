public enum DNSLookupError: Error, Hashable {
    case timeout
    case lookupFailed(code: Int32)
    case responseNotSecuredWithDNSSEC
}
