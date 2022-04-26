import XCTest
import dnssd
@testable import PexipInfinityClient

final class NodeResolverTests: XCTestCase {
    private var resolver: NodeResolver!
    private var dnsLookupClient: DNSLookupClientMock!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        dnsLookupClient = DNSLookupClientMock()
        resolver = DefaultNodeResolver(
            dnsLookupClient: dnsLookupClient,
            dnssec: false
        )
    }

    // MARK: - SRV records

    func testResolveNodeWithSRVRecord() async throws {
        let record = SRVRecord(
            priority: 10,
            weight: 20,
            port: 1720,
            target: "px01.vc.example.com"
        )
        dnsLookupClient.srvRecords = .success([record])
        dnsLookupClient.aRecords = .success([])

        let nodes = try await resolver.resolveNodes(for: "vc.example.com")

        XCTAssertEqual(
            dnsLookupClient.steps,
            [.srvRecordsLookup(name: "_pexapp._tcp.vc.example.com", dnssec: false)]
        )
        XCTAssertEqual(
            nodes,
            [URL(string: "http://px01.vc.example.com:1720")!]
        )
    }

    func testResolveNodeWithSRVRecordAndDefaultHTTPSPort() async throws {
        let record = SRVRecord(
            priority: 10,
            weight: 20,
            port: 443,
            target: "px01.vc.example.com"
        )
        dnsLookupClient.srvRecords = .success([record])
        dnsLookupClient.aRecords = .success([])

        let nodes = try await resolver.resolveNodes(for: "vc.example.com")

        XCTAssertEqual(
            dnsLookupClient.steps,
            [.srvRecordsLookup(name: "_pexapp._tcp.vc.example.com", dnssec: false)]
        )
        XCTAssertEqual(
            nodes,
            [URL(string: "https://px01.vc.example.com:443")!]
        )
    }

    func testResolveNodeWithSRVRecordAndDefaultHTTPPort() async throws {
        let record = SRVRecord(
            priority: 10,
            weight: 20,
            port: 80,
            target: "px01.vc.example.com"
        )
        dnsLookupClient.srvRecords = .success([record])
        dnsLookupClient.aRecords = .success([])

        let nodes = try await resolver.resolveNodes(for: "vc.example.com")

        XCTAssertEqual(
            dnsLookupClient.steps,
            [.srvRecordsLookup(name: "_pexapp._tcp.vc.example.com", dnssec: false)]
        )
        XCTAssertEqual(
            nodes,
            [URL(string: "http://px01.vc.example.com:80")!]
        )
    }

    func testResolveNodeWithSRVRecordLookupError() async throws {
        dnsLookupClient.srvRecords = .failure(DNSLookupError.timeout)
        dnsLookupClient.aRecords = .success([])

        let nodes = try await resolver.resolveNodes(for: "vc.example.com")

        XCTAssertTrue(nodes.isEmpty)
        XCTAssertEqual(
            dnsLookupClient.steps,
            [
                .srvRecordsLookup(name: "_pexapp._tcp.vc.example.com", dnssec: false),
                .aRecordsLookup(name: "vc.example.com", dnssec: false)
            ]
        )
    }

    // MARK: - A records

    func testResolveNodeWithARecord() async throws {
        let record = ARecord(ipv4Address: "198.51.100.40")
        dnsLookupClient.srvRecords = .success([])
        dnsLookupClient.aRecords = .success([record])

        let nodes = try await resolver.resolveNodes(for: "example.com")

        XCTAssertEqual(
            dnsLookupClient.steps,
            [
                .srvRecordsLookup(name: "_pexapp._tcp.example.com", dnssec: false),
                .aRecordsLookup(name: "example.com", dnssec: false)
            ]
        )
        XCTAssertEqual(nodes, [URL(string: "https://198.51.100.40")!])
    }

    func testResolveNodeWithARecordLookupError() async throws {
        dnsLookupClient.srvRecords = .success([])
        dnsLookupClient.aRecords = .failure(DNSLookupError.timeout)

        do {
            _ = try await resolver.resolveNodes(for: "vc.example.com")
            XCTFail("Should fail with error")
        } catch {
            XCTAssertEqual(error as? DNSLookupError, .timeout)
        }

        XCTAssertEqual(
            dnsLookupClient.steps,
            [
                .srvRecordsLookup(name: "_pexapp._tcp.vc.example.com", dnssec: false),
                .aRecordsLookup(name: "vc.example.com", dnssec: false)
            ]
        )
    }

    // MARK: - Errors

    func testResolveNodeWithNoRecordsFound() async throws {
        dnsLookupClient.srvRecords = .success([])
        dnsLookupClient.aRecords = .success([])

        let nodes = try await resolver.resolveNodes(for: "vc.example.com")
        XCTAssertTrue(nodes.isEmpty)

        XCTAssertEqual(
            dnsLookupClient.steps,
            [
                .srvRecordsLookup(name: "_pexapp._tcp.vc.example.com", dnssec: false),
                .aRecordsLookup(name: "vc.example.com", dnssec: false)
            ]
        )
    }
}

// MARK: - Mocks

private final class DNSLookupClientMock: DNSLookupClientProtocol {
    enum Step: Equatable {
        case srvRecordsLookup(name: String, dnssec: Bool)
        case aRecordsLookup(name: String, dnssec: Bool)
    }

    var srvRecords: Result<[SRVRecord], Error> = .success([])
    var aRecords: Result<[ARecord], Error> = .success([])
    private(set) var steps = [Step]()

    func resolveSRVRecords(for name: String, dnssec: Bool) async throws -> [SRVRecord] {
        steps.append(.srvRecordsLookup(name: name, dnssec: dnssec))
        return try srvRecords.get()
    }

    func resolveARecords(for name: String, dnssec: Bool) async throws -> [ARecord] {
        steps.append(.aRecordsLookup(name: name, dnssec: dnssec))
        return try aRecords.get()
    }
}
