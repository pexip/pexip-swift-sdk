import Foundation
import dnssd

final class DNSLookupQuery {
    final class Result {
        var records = [Data]()
    }
    
    let domain: String
    let serviceType: Int
    let handler: DNSServiceQueryRecordReply
    var result = Result()
    
    // MARK: - Init
    
    init(
        domain: String,
        serviceType: Int,
        handler: @escaping DNSServiceQueryRecordReply
    ) {
        self.domain = domain
        self.serviceType = serviceType
        self.handler = handler
    }
}
