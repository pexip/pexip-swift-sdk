import XCTest
import dnssd
@testable import DNSLookup
@testable import ClientControl

final class NodeResolverTests: XCTestCase {
    private var resolver: NodeResolver!
    private var dnsLookupService: DNSLookupService!
    private var dnsClient: DNSClientMock!
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        dnsClient = DNSClientMock()
        dnsLookupService = DNSLookupService(client: dnsClient)
        resolver = NodeResolver(dnsLookupService: dnsLookupService)
    }
    
    // MARK: - Tests
    
    func testResolveNodeURLWithSRVRecord() async throws {
        let record = SRVRecord.Stub.default
        dnsClient.result = .success([record.data])
        dnsClient.serviceType = kDNSServiceType_SRV
        
        let url = try await resolver.resolveNodeURL(for: "conference@vc.example.com")
        XCTAssertEqual(dnsClient.name, "_pexapp._tcp.vc.example.com")
        XCTAssertEqual(url, URL(string: "https://px01.vc.example.com")!)
    }
    
    func testResolveWithARecord() async throws {
        let record = ARecord.Stub.default
        dnsClient.serviceType = kDNSServiceType_A
        dnsClient.result = .success([record.data])
        
        let url = try await resolver.resolveNodeURL(for: "conference@example.com")
        XCTAssertEqual(dnsClient.name, "example.com")
        XCTAssertEqual(url, URL(string: "https://198.51.100.40")!)
    }
    
    func testResolveNodeURLWithInvalidConferenceURI() async throws {
        dnsClient.serviceType = kDNSServiceType_SRV
        
        do {
            _ = try await resolver.resolveNodeURL(for: "vc.example.com")
            XCTFail("Should fail with error")
        } catch {
            XCTAssertTrue(error is NodeResolverError)
        }
        
        XCTAssertNil(dnsClient.name)
    }
    
    func testResolveNodeURLWithServiceError() async throws {
        dnsClient.result = .failure(DNSClientError.timeout)
        dnsClient.serviceType = kDNSServiceType_SRV
        
        do {
            _ = try await resolver.resolveNodeURL(for: "conference@vc.example.com")
            XCTFail("Should fail with error")
        } catch {
            XCTAssertEqual(error as? DNSClientError, .timeout)
        }
        
        XCTAssertEqual(dnsClient.name, "_pexapp._tcp.vc.example.com")
    }
}

// MARK: - Mocks

final class DNSClientMock: DNSClient {
    var result: Result<[Data], Error> = .success([])
    var name: String?
    var serviceType = kDNSServiceType_SRV
    
    func resolveRecords(
        forName name: String,
        serviceType: Int,
        timeout: __darwin_time_t
    ) throws -> [Data] {
        self.name = name
        
        if serviceType == self.serviceType {
            return try result.get()
        } else {
            return []
        }
    }
}
