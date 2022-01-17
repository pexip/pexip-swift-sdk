import XCTest
import dnssd
@testable import DNSLookup

final class DNSClientTests: XCTestCase {
    private var client: DNSServiceDiscoveryClient!
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        client = DNSServiceDiscoveryClient()
    }
    
    // MARK: - Tests
    
    func testRecordsFromContext() throws {
        let context = DNSRecordContext()
        let data = "test".data(using: .utf8)!
        context.records = [data]
        
        let records = try client.records(
            from: context,
            fileDescriptorsNumber: 1,
            errorCode: Int32(kDNSServiceErr_NoError)
        )
        
        XCTAssertEqual(records, [data])
    }
    
    func testRecordsFromContextWithErrno() throws {
        let context = DNSRecordContext()
        
        XCTAssertThrowsError(
            try client.records(
                from: context,
                fileDescriptorsNumber: -1,
                errorCode: Int32(kDNSServiceErr_NoError)
            )
        ) { error in
            XCTAssertEqual(
                error as? DNSClientError,
                DNSClientError.error(errno, String(utf8String: strerror(errno)))
            )
        }
    }
    
    func testRecordsFromContextWithTimeout() throws {
        let context = DNSRecordContext()
        
        XCTAssertThrowsError(
            try client.records(
                from: context,
                fileDescriptorsNumber: 0,
                errorCode: Int32(kDNSServiceErr_NoError)
            )
        ) { error in
            XCTAssertEqual(error as? DNSClientError, .timeout)
        }
    }
    
    func testRecordsFromContextWithErrorCode() throws {
        let context = DNSRecordContext()
        let errorCode = Int32(kDNSServiceErr_Unsupported)
        
        XCTAssertThrowsError(
            try client.records(
                from: context,
                fileDescriptorsNumber: 1,
                errorCode: errorCode
            )
        ) { error in
            XCTAssertEqual(
                error as? DNSClientError,
                DNSClientError.error(errorCode, nil)
            )
        }
    }
    
    func testRecordsFromContextWithContextError() throws {
        let context = DNSRecordContext()
        context.error = DNSClientError.error(10001, "Test")
        
        XCTAssertThrowsError(
            try client.records(
                from: context,
                fileDescriptorsNumber: 2,
                errorCode: Int32(kDNSServiceErr_NoError)
            )
        ) { error in
            XCTAssertEqual(error as? DNSClientError, context.error)
        }
    }
    
    func testHandleQueryRecordReply() throws {
        var context = DNSRecordContext()
        let bytes = [0x00, 0x0A]
        
        try DNSServiceDiscoveryClient.handleQueryRecordReply(
            bytes: bytes,
            length: 2,
            context: &context,
            errorCode: Int32(kDNSServiceErr_NoError)
        )
        
        XCTAssertEqual(context.records, [Data(bytes: bytes, count: 2)])
    }
    
    func testHandleQueryRecordReplyWithNoData() throws {
        var context = DNSRecordContext()
        
        try DNSServiceDiscoveryClient.handleQueryRecordReply(
            bytes: nil,
            length: 0,
            context: &context,
            errorCode: Int32(kDNSServiceErr_NoError)
        )
        
        XCTAssertTrue(context.records.isEmpty)
    }
    
    func testHandleQueryRecordReplyWithEmptyData() throws {
        var context = DNSRecordContext()
        let bytes = [UInt8]()
        
        try DNSServiceDiscoveryClient.handleQueryRecordReply(
            bytes: bytes,
            length: 0,
            context: &context,
            errorCode: Int32(kDNSServiceErr_NoError)
        )
        
        XCTAssertTrue(context.records.isEmpty)
    }
    
    func testHandleQueryRecordReplyWithInvalidContext() throws {
        let bytes = [0x00, 0x0A]

        XCTAssertThrowsError(
            try DNSServiceDiscoveryClient.handleQueryRecordReply(
                bytes: bytes,
                length: 2,
                context: nil,
                errorCode: Int32(kDNSServiceErr_NoError)
            )
        ) { error in
            XCTAssertEqual(error as? DNSClientError, .invalidContext)
        }
    }
    
    func testHandleQueryRecordReplyWithErrorCode() throws {
        var context = DNSRecordContext()
        let bytes = [0x00, 0x0A]
        let errorCode = Int32(kDNSServiceErr_Unsupported)
        
        XCTAssertThrowsError(
            try DNSServiceDiscoveryClient.handleQueryRecordReply(
                bytes: bytes,
                length: 2,
                context: &context,
                errorCode: errorCode
            )
        ) { error in
            XCTAssertEqual(
                error as? DNSClientError,
                DNSClientError.error(errorCode, nil)
            )
        }
    }
    
    func testHandleQueryRecordReplyWithContextError() throws {
        var context = DNSRecordContext()
        context.error = DNSClientError.error(10001, "Test")
        
        let bytes = [0x00, 0x0A]

        XCTAssertThrowsError(
            try DNSServiceDiscoveryClient.handleQueryRecordReply(
                bytes: bytes,
                length: 2,
                context: &context,
                errorCode: Int32(kDNSServiceErr_NoError)
            )
        ) { error in
            XCTAssertEqual(error as? DNSClientError, context.error)
        }
    }
}
