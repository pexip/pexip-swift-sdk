import Foundation
import dnssd

// MARK: - Protocol

protocol DNSClient {
    func resolveRecords(
        forName name: String,
        serviceType: Int,
        timeout: __darwin_time_t
    ) throws -> [Data]
}

// MARK: - Implementation

final class DNSServiceDiscoveryClient: DNSClient {
    func resolveRecords(
        forName name: String,
        serviceType: Int,
        timeout: __darwin_time_t
    ) throws -> [Data] {
        var context = DNSRecordContext()
        let sdRef: UnsafeMutablePointer<DNSServiceRef?> = .allocate(capacity: MemoryLayout<DNSServiceRef>.size)
        let serviceClass = UInt16(kDNSServiceClass_IN)
        let reply = DNSServiceDiscoveryClient.queryRecordReply
        let errorCode = DNSServiceQueryRecord(sdRef, 0, 0, name, UInt16(serviceType), serviceClass, reply, &context)
        
        defer {
            DNSServiceRefDeallocate(sdRef.pointee)
        }
        
        guard errorCode == kDNSServiceErr_NoError else {
            throw DNSClientError.error(errorCode, nil)
        }

        let fd = DNSServiceRefSockFD(sdRef.pointee)
        var fdSet = fd_set()
        var timeout = timeval(tv_sec: timeout, tv_usec: 0)

        __darwin_fd_set(fd, &fdSet)
        
        // Wait for results and return resolved records
        let result = select(fd + 1, &fdSet, nil, nil, &timeout)
        let resultErrorCode = DNSServiceProcessResult(sdRef.pointee)
        
        return try records(from: context, fileDescriptorsNumber: result, errorCode: resultErrorCode)
    }
    
    func records(
        from context: DNSRecordContext,
        fileDescriptorsNumber: Int32,
        errorCode: Int32
    ) throws -> [Data] {
        switch fileDescriptorsNumber {
        case -1:
            throw DNSClientError.error(errno, String(utf8String: strerror(errno)))
        case 0:
            throw DNSClientError.timeout
        default:
            if errorCode != kDNSServiceErr_NoError {
                throw DNSClientError.error(errorCode, nil)
            } else if let error = context.error {
                throw error
            } else {
                return context.records
            }
        }
    }
    
    static func handleQueryRecordReply(
        bytes: UnsafeRawPointer?,
        length: UInt16,
        context: UnsafeMutableRawPointer?,
        errorCode: Int32
    ) throws {
        guard let context = context?.assumingMemoryBound(to: DNSRecordContext.self).pointee else {
            throw DNSClientError.invalidContext
        }
        
        if errorCode != kDNSServiceErr_NoError {
            context.error = .error(errorCode, nil)
        }
        
        if let error = context.error {
            throw error
        } else if let bytes = bytes, length > 0 {
            context.records.append(Data(bytes: bytes, count: Int(length)))
        }
    }
    
    private static let queryRecordReply: DNSServiceQueryRecordReply = {
        _, _, _, errorCode, _, _, _, length, bytes, _, context in
        
        try? handleQueryRecordReply(
            bytes: bytes,
            length: length,
            context: context,
            errorCode: errorCode
        )
    }
}

// MARK: - Errors

enum DNSClientError: Error, Hashable {
    case error(Int32, String?)
    case timeout
    case invalidContext
}

// MARK: - Internal types

final class DNSRecordContext {
    var records = [Data]()
    var error: DNSClientError?
}
