import XCTest
@testable import DNSLookup

final class DNSLookupServiceTests: XCTestCase {
    private var service: DNSLookupService!
    private var client: DNSClientMock!
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        client = DNSClientMock()
        service = DNSLookupService(client: client)
    }
    
    // MARK: - Tests
    
    func testInit() {
        // Default timeout
        XCTAssertEqual(service.timeout, 5)
        // Custom timeout
        XCTAssertEqual(DNSLookupService(client: client, timeout: 10).timeout, 10)
    }

    func testResolveSRVRecords() async throws {
        let root = SRVRecord.Stub.root
        let record = SRVRecord.Stub.default
        
        client.result = .success([root.data, record.data])
        
        let records = try await service.resolveSRVRecords(
            service: "h323cs",
            proto: "tcp",
            name: "vc.example.com"
        )
        
        XCTAssertEqual(client.name, "_h323cs._tcp.vc.example.com")
        // Sorted records
        XCTAssertEqual(records, [record.instance, root.instance])
    }
    
    func testResolveSRVRecordsWithRootDomain() async throws {
        let record = SRVRecord.Stub.root
        client.result = .success([record.data])
        
        let records = try await service.resolveSRVRecords(
            service: "h323cs",
            proto: "tcp",
            name: "vc.example.com"
        )
        
        XCTAssertEqual(client.name, "_h323cs._tcp.vc.example.com")
        XCTAssertTrue(records.isEmpty)
    }
    
    func testResolveSRVRecordsWithError() async throws {
        client.result = .failure(DNSClientError.timeout)
        
        do {
            _ = try await service.resolveSRVRecords(
                service: "h323cs",
                proto: "tcp",
                name: "vc.example.com"
            )
            XCTFail("Should fail with error")
        } catch {
            XCTAssertEqual(error as? DNSClientError, .timeout)
        }
        
        XCTAssertEqual(client.name, "_h323cs._tcp.vc.example.com")
    }
    
    func testResolveARecords() async throws {
        let record = ARecord.Stub.default
        client.result = .success([record.data])
        
        let records = try await service.resolveARecords(
            for: "px01.vc.example.com"
        )
        
        XCTAssertEqual(client.name, "px01.vc.example.com")
        XCTAssertEqual(records, [record.instance])
    }
    
    func testResolveARecordsWithError() async throws {
        client.result = .failure(DNSClientError.timeout)
        
        do {
            _ = try await service.resolveARecords(for: "px01.vc.example.com")
            XCTFail("Should fail with error")
        } catch {
            XCTAssertEqual(error as? DNSClientError, .timeout)
        }
        
        XCTAssertEqual(client.name, "px01.vc.example.com")
    }
}

// MARK: - Mocks

final class DNSClientMock: DNSClient {
    var result: Result<[Data], Error> = .success([])
    var name: String?
    
    func resolveRecords(
        forName name: String,
        serviceType: Int,
        timeout: __darwin_time_t
    ) throws -> [Data] {
        self.name = name
        return try result.get()
    }
}
