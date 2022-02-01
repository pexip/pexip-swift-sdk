import XCTest
import dnssd
@testable import PexipVideo

final class NodeResolverTests: XCTestCase {
    private var resolver: NodeResolver!
    private var dnsLookupClient: DNSLookupClientMock!
    private var statusClient: NodeStatusClientMock!
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        dnsLookupClient = DNSLookupClientMock()
        statusClient = NodeStatusClientMock()
        resolver = NodeResolver(
            dnsLookupClient: dnsLookupClient,
            statusClient: statusClient
        )
    }
    
    // MARK: - SRV records

    func testResolveNodeAddressWithSRVRecord() async throws {
        let record = SRVRecord(
            priority: 10,
            weight: 20,
            port: 1720,
            target: "px01.vc.example.com"
        )
        dnsLookupClient.srvRecords = .success([record])
        dnsLookupClient.aRecords = .success([])

        let address = try await resolver.resolveNodeAddress(for: "vc.example.com")

        XCTAssertEqual(
            dnsLookupClient.steps,
            [.srvRecordsLookup(service: "pexapp", proto: "tcp", name: "vc.example.com")]
        )
        XCTAssertEqual(address, URL(string: "http://px01.vc.example.com:1720")!)
    }
    
    func testResolveNodeAddressWithSRVRecordAndDefaultHTTPSPort() async throws {
        let record = SRVRecord(
            priority: 10,
            weight: 20,
            port: 443,
            target: "px01.vc.example.com"
        )
        dnsLookupClient.srvRecords = .success([record])
        dnsLookupClient.aRecords = .success([])

        let address = try await resolver.resolveNodeAddress(for: "vc.example.com")

        XCTAssertEqual(
            dnsLookupClient.steps,
            [.srvRecordsLookup(service: "pexapp", proto: "tcp", name: "vc.example.com")]
        )
        XCTAssertEqual(address, URL(string: "https://px01.vc.example.com")!)
    }
    
    func testResolveNodeAddressWithSRVRecordAndDefaultHTTPPort() async throws {
        let record = SRVRecord(
            priority: 10,
            weight: 20,
            port: 80,
            target: "px01.vc.example.com"
        )
        dnsLookupClient.srvRecords = .success([record])
        dnsLookupClient.aRecords = .success([])

        let address = try await resolver.resolveNodeAddress(for: "vc.example.com")

        XCTAssertEqual(
            dnsLookupClient.steps,
            [.srvRecordsLookup(service: "pexapp", proto: "tcp", name: "vc.example.com")]
        )
        XCTAssertEqual(address, URL(string: "http://px01.vc.example.com")!)
    }
    
    func testResolveNodeAddressWithSRVRecordInMaintenanceMode() async throws {
        let recordA = SRVRecord(
            priority: 5,
            weight: 30,
            port: 1720,
            target: "px01.vc.example.com"
        )
        
        let recordB = SRVRecord(
            priority: 10,
            weight: 20,
            port: 1721,
            target: "px02.vc.example.com"
        )
        
        dnsLookupClient.srvRecords = .success([recordA, recordB])
        dnsLookupClient.aRecords = .success([])
        statusClient.targetsInMaintenance = [recordA.target]

        let address = try await resolver.resolveNodeAddress(for: "vc.example.com")

        XCTAssertEqual(
            dnsLookupClient.steps,
            [.srvRecordsLookup(service: "pexapp", proto: "tcp", name: "vc.example.com")]
        )
        // recordB
        XCTAssertEqual(address, URL(string: "http://px02.vc.example.com:1721")!)
    }
    
    func testResolveNodeAddressWithSRVRecordLookupError() async throws {
        dnsLookupClient.srvRecords = .failure(DNSLookupError.timeout)
        dnsLookupClient.aRecords = .success([])

        do {
            _ = try await resolver.resolveNodeAddress(for: "vc.example.com")
            XCTFail("Should fail with error")
        } catch {
            XCTAssertEqual(error as? DNSLookupError, .timeout)
        }

        XCTAssertEqual(
            dnsLookupClient.steps,
            [.srvRecordsLookup(service: "pexapp", proto: "tcp", name: "vc.example.com")]
        )
    }
    
    func testResolveNodeAddressWithSRVRecordAndStatusClientError() async throws {
        let record = SRVRecord(
            priority: 10,
            weight: 20,
            port: 1720,
            target: "px01.vc.example.com"
        )
        
        dnsLookupClient.srvRecords = .success([record])
        dnsLookupClient.aRecords = .success([])
        statusClient.error = URLError(.badURL)

        do {
            _ = try await resolver.resolveNodeAddress(for: "vc.example.com")
            XCTFail("Should fail with error")
        } catch {
            XCTAssertEqual((error as? URLError)?.code, .badURL)
        }

        XCTAssertEqual(
            dnsLookupClient.steps,
            [.srvRecordsLookup(service: "pexapp", proto: "tcp", name: "vc.example.com")]
        )
    }
    
    // MARK: - A records

    func testResolveNodeAddressWithARecord() async throws {
        let record = ARecord(ipv4Address: "198.51.100.40")
        dnsLookupClient.srvRecords = .success([])
        dnsLookupClient.aRecords = .success([record])

        let address = try await resolver.resolveNodeAddress(for: "example.com")

        XCTAssertEqual(
            dnsLookupClient.steps,
            [
                .srvRecordsLookup(service: "pexapp", proto: "tcp", name: "example.com"),
                .aRecordsLookup(name: "example.com")
            ]
        )
        XCTAssertEqual(address, URL(string: "https://198.51.100.40")!)
    }
    
    func testResolveNodeAddressWithARecordInMaintenanceMode() async throws {
        let recordA = ARecord(ipv4Address: "198.51.100.40")
        let recordB = ARecord(ipv4Address: "198.51.100.41")
        
        dnsLookupClient.srvRecords = .success([])
        dnsLookupClient.aRecords = .success([recordA, recordB])
        statusClient.targetsInMaintenance = [recordA.ipv4Address]

        let address = try await resolver.resolveNodeAddress(for: "vc.example.com")

        XCTAssertEqual(
            dnsLookupClient.steps,
            [
                .srvRecordsLookup(service: "pexapp", proto: "tcp", name: "vc.example.com"),
                .aRecordsLookup(name: "vc.example.com")
            ]
        )
        // recordB
        XCTAssertEqual(address, URL(string: "https://198.51.100.41")!)
    }

    func testResolveNodeAddressWithARecordLookupError() async throws {
        dnsLookupClient.srvRecords = .success([])
        dnsLookupClient.aRecords = .failure(DNSLookupError.timeout)

        do {
            _ = try await resolver.resolveNodeAddress(for: "vc.example.com")
            XCTFail("Should fail with error")
        } catch {
            XCTAssertEqual(error as? DNSLookupError, .timeout)
        }

        XCTAssertEqual(
            dnsLookupClient.steps,
            [
                .srvRecordsLookup(service: "pexapp", proto: "tcp", name: "vc.example.com"),
                .aRecordsLookup(name: "vc.example.com")
            ]
        )
    }
    
    func testResolveNodeAddressWithARecordAndStatusClientError() async throws {
        let record = ARecord(ipv4Address: "198.51.100.40")
        
        dnsLookupClient.srvRecords = .success([])
        dnsLookupClient.aRecords = .success([record])
        statusClient.error = URLError(.badURL)

        do {
            _ = try await resolver.resolveNodeAddress(for: "vc.example.com")
            XCTFail("Should fail with error")
        } catch {
            XCTAssertEqual((error as? URLError)?.code, .badURL)
        }

        XCTAssertEqual(
            dnsLookupClient.steps,
            [
                .srvRecordsLookup(service: "pexapp", proto: "tcp", name: "vc.example.com"),
                .aRecordsLookup(name: "vc.example.com")
            ]
        )
    }
    
    // MARK: - Errors
    
    func testResolveNodeAddressWithNoRecordsFound() async throws {
        dnsLookupClient.srvRecords = .success([])
        dnsLookupClient.aRecords = .success([])
        
        do {
            _ = try await resolver.resolveNodeAddress(for: "vc.example.com")
            XCTFail("Should fail with error")
        } catch {
            XCTAssertEqual(error as? NodeError, .nodeNotFound)
        }
        
        XCTAssertEqual(
            dnsLookupClient.steps,
            [
                .srvRecordsLookup(service: "pexapp", proto: "tcp", name: "vc.example.com"),
                .aRecordsLookup(name: "vc.example.com")
            ]
        )
    }
}

// MARK: - Mocks

private final class DNSLookupClientMock: DNSLookupClientProtocol {
    enum Step: Equatable {
        case srvRecordsLookup(service: String, proto: String, name: String)
        case aRecordsLookup(name: String)
    }
    
    var srvRecords: Result<[SRVRecord], Error> = .success([])
    var aRecords: Result<[ARecord], Error> = .success([])
    private(set) var steps = [Step]()
    
    func resolveSRVRecords(service: String, proto: String, name: String) async throws -> [SRVRecord] {
        steps.append(.srvRecordsLookup(service: service, proto: proto, name: name))
        return try srvRecords.get()
    }

    func resolveARecords(for name: String) async throws -> [ARecord] {
        steps.append(.aRecordsLookup(name: name))
        return try aRecords.get()
    }
}

private final class NodeStatusClientMock: NodeStatusClientProtocol {
    var error: Error?
    var targetsInMaintenance = Set<String>()
    
    func isInMaintenanceMode(nodeAddress: URL) async throws -> Bool {
        if let error = error {
            throw error
        }
        
        return targetsInMaintenance.contains(where: {
            nodeAddress.absoluteString.contains($0)
        })
    }
}
