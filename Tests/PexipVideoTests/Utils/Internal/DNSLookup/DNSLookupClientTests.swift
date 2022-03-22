import XCTest
import dnssd
@testable import PexipVideo

final class DNSLookupClientTests: XCTestCase {
    private var client: DNSLookupClient!
    private var task: DNSLookupTaskMock!

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        let task = DNSLookupTaskMock()
        self.task = task

        client = DNSLookupClient(
            timeout: 0.1,
            makeLookupTask: { query  in
                task.query = query
                return task
            }
        )
    }

    // MARK: - Test init

    func testInit() {
        // Default task
        let query = DNSLookupQuery(
            domain: "example.org",
            serviceType: kDNSServiceType_A,
            handler: { _, _, _, _, _, _, _, _, _, _, _ in }
        )
        XCTAssertTrue(DNSLookupClient().makeLookupTask(query) is DNSLookupTask)
        // Default timeout
        XCTAssertEqual(DNSLookupClient().timeout, 5)
        // Custom timeout
        XCTAssertEqual(DNSLookupClient(timeout: 10).timeout, 10)
    }

    // MARK: - SRV records

    func testResolveSRVRecords() async throws {
        let root = SRVRecord.Stub.root
        let record = SRVRecord.Stub.default

        task.result = [root.data, record.data]

        let records = try await client.resolveSRVRecords(
            for: "_h323cs._tcp.vc.example.com"
        )

        try await Task.sleep(seconds: 0.1)

        XCTAssertEqual(task.steps, [.prepare(flags: 0), .start, .cancel])
        XCTAssertEqual(task.query.domain, "_h323cs._tcp.vc.example.com")
        XCTAssertEqual(task.query.serviceType, kDNSServiceType_SRV)
        // Sorted records
        XCTAssertEqual(records, [record.instance, root.instance])
    }

    func testResolveSRVRecordsWithRootDomain() async throws {
        let record = SRVRecord.Stub.root
        task.result = [record.data]

        let records = try await client.resolveSRVRecords(
            for: "_h323cs._tcp.vc.example.com"
        )

        try await Task.sleep(seconds: 0.1)

        XCTAssertEqual(task.steps, [.prepare(flags: 0), .start, .cancel])
        XCTAssertEqual(task.query.domain, "_h323cs._tcp.vc.example.com")
        XCTAssertEqual(task.query.serviceType, kDNSServiceType_SRV)
        XCTAssertTrue(records.isEmpty)
    }

    func testResolveSRVRecordsWithInvalidData() async throws {
        task.result = [try XCTUnwrap("test".data(using: .utf8))]

        do {
            _ = try await client.resolveSRVRecords(
                for: "_h323cs._tcp.vc.example.com"
            )
            XCTFail("Should fail with error")
        } catch {
            XCTAssertTrue(error is SRVRecordError)
        }

        try await Task.sleep(seconds: 0.1)

        XCTAssertEqual(task.steps, [.prepare(flags: 0), .start, .cancel])
        XCTAssertEqual(task.query.domain, "_h323cs._tcp.vc.example.com")
        XCTAssertEqual(task.query.serviceType, kDNSServiceType_SRV)
    }

    func testResolveSRVRecordsWithErrorInPreparation() async throws {
        task.preparationErrorCode = Int32(kDNSServiceErr_ServiceNotRunning)

        do {
            _ = try await client.resolveSRVRecords(
                for: "_h323cs._tcp.vc.example.com"
            )
            XCTFail("Should fail with error")
        } catch {
            XCTAssertEqual(
                error as? DNSLookupError,
                .lookupFailed(code: task.preparationErrorCode)
            )
        }

        try await Task.sleep(seconds: 0.1)

        XCTAssertEqual(task.steps, [.prepare(flags: 0), .cancel])
        XCTAssertEqual(task.query.domain, "_h323cs._tcp.vc.example.com")
        XCTAssertEqual(task.query.serviceType, kDNSServiceType_SRV)
    }

    func testResolveSRVRecordsWithErrorInProcessing() async throws {
        task.processingErrorCode = Int32(kDNSServiceErr_NotPermitted)

        do {
            _ = try await client.resolveSRVRecords(
                for: "_h323cs._tcp.vc.example.com"
            )
            XCTFail("Should fail with error")
        } catch {
            XCTAssertEqual(
                error as? DNSLookupError,
                .lookupFailed(code: task.processingErrorCode)
            )
        }

        try await Task.sleep(seconds: 0.1)

        XCTAssertEqual(task.steps, [.prepare(flags: 0), .start, .cancel])
        XCTAssertEqual(task.query.domain, "_h323cs._tcp.vc.example.com")
        XCTAssertEqual(task.query.serviceType, kDNSServiceType_SRV)
    }

    func testResolveSRVRecordsWithTimeoutError() async throws {
        task.startDelay = 10

        do {
            _ = try await client.resolveSRVRecords(
                for: "_h323cs._tcp.vc.example.com"
            )
            XCTFail("Should fail with error")
        } catch {
            XCTAssertEqual(error as? DNSLookupError, .timeout)
        }

        try await Task.sleep(seconds: 0.1)

        XCTAssertEqual(task.steps, [.prepare(flags: 0), .start, .cancel])
        XCTAssertEqual(task.query.domain, "_h323cs._tcp.vc.example.com")
        XCTAssertEqual(task.query.serviceType, kDNSServiceType_SRV)
    }

    func testResolveSRVRecordsWithDNSSECSecure() async throws {
        let record = SRVRecord.Stub.default

        task.resultFlags = kDNSServiceFlagsSecure
        task.result = [record.data]

        let records = try await client.resolveSRVRecords(
            for: "_h323cs._tcp.vc.example.com",
            dnssec: true
        )

        try await Task.sleep(seconds: 0.1)

        XCTAssertEqual(
            task.steps,
            [.prepare(flags: kDNSServiceFlagsValidate), .start, .cancel]
        )
        XCTAssertEqual(task.query.domain, "_h323cs._tcp.vc.example.com")
        XCTAssertEqual(task.query.serviceType, kDNSServiceType_SRV)
        XCTAssertEqual(records, [record.instance])
    }

    func testResolveSRVRecordsWithDNSSECInsecure() async throws {
        let record = SRVRecord.Stub.default

        task.resultFlags = kDNSServiceFlagsInsecure
        task.result = [record.data]

        do {
            _ = try await client.resolveSRVRecords(
                for: "_h323cs._tcp.vc.example.com",
                dnssec: true
            )
            XCTFail("Should fail with error")
        } catch {
            XCTAssertEqual(
                error as? DNSLookupError,
                .responseNotSecuredWithDNSSEC
            )
        }

        try await Task.sleep(seconds: 0.1)

        XCTAssertEqual(
            task.steps,
            [.prepare(flags: kDNSServiceFlagsValidate), .start, .cancel]
        )
        XCTAssertEqual(task.query.domain, "_h323cs._tcp.vc.example.com")
        XCTAssertEqual(task.query.serviceType, kDNSServiceType_SRV)
    }

    // MARK: - A records

    func testResolveARecords() async throws {
        let record = ARecord.Stub.default
        task.result = [record.data]

        let records = try await client.resolveARecords(
            for: "px01.vc.example.com"
        )

        try await Task.sleep(seconds: 0.1)

        XCTAssertEqual(task.steps, [.prepare(flags: 0), .start, .cancel])
        XCTAssertEqual(task.query.domain, "px01.vc.example.com")
        XCTAssertEqual(task.query.serviceType, kDNSServiceType_A)
        XCTAssertEqual(records, [record.instance])
    }

    func testResolveARecordsWithError() async throws {
        task.preparationErrorCode = Int32(kDNSServiceErr_ServiceNotRunning)

        do {
            _ = try await client.resolveARecords(for: "px01.vc.example.com")
            XCTFail("Should fail with error")
        } catch {
            XCTAssertEqual(
                error as? DNSLookupError,
                .lookupFailed(code: task.preparationErrorCode)
            )
        }

        try await Task.sleep(seconds: 0.1)

        XCTAssertEqual(task.steps, [.prepare(flags: 0), .cancel])
        XCTAssertEqual(task.query.domain, "px01.vc.example.com")
        XCTAssertEqual(task.query.serviceType, kDNSServiceType_A)
    }

    func testResolveARecordsWithInvalidData() async throws {
        task.result = [try XCTUnwrap("invalid data string".data(using: .utf8))]

        do {
            _ = try await client.resolveARecords(for: "px01.vc.example.com")
            XCTFail("Should fail with error")
        } catch {
            XCTAssertTrue(error is ARecordError)
        }

        try await Task.sleep(seconds: 0.1)

        XCTAssertEqual(task.steps, [.prepare(flags: 0), .start, .cancel])
        XCTAssertEqual(task.query.domain, "px01.vc.example.com")
        XCTAssertEqual(task.query.serviceType, kDNSServiceType_A)
    }

    func testResolveARecordsWithDNSSECSecure() async throws {
        let record = ARecord.Stub.default
        task.result = [record.data]
        task.resultFlags = kDNSServiceFlagsSecure

        let records = try await client.resolveARecords(
            for: "px01.vc.example.com",
            dnssec: true
        )

        try await Task.sleep(seconds: 0.1)

        XCTAssertEqual(
            task.steps,
            [.prepare(flags: kDNSServiceFlagsValidate), .start, .cancel]
        )
        XCTAssertEqual(task.query.domain, "px01.vc.example.com")
        XCTAssertEqual(task.query.serviceType, kDNSServiceType_A)
        XCTAssertEqual(records, [record.instance])
    }

    func testResolveARecordsWithDNSSECInsecure() async throws {
        let record = ARecord.Stub.default
        task.result = [record.data]
        task.resultFlags = kDNSServiceFlagsInsecure

        do {
            _ = try await client.resolveARecords(
                for: "px01.vc.example.com",
                dnssec: true
            )
            XCTFail("Should fail with error")
        } catch {
            XCTAssertEqual(
                error as? DNSLookupError,
                .responseNotSecuredWithDNSSEC
            )
        }

        try await Task.sleep(seconds: 0.1)

        XCTAssertEqual(
            task.steps,
            [.prepare(flags: kDNSServiceFlagsValidate), .start, .cancel]
        )
        XCTAssertEqual(task.query.domain, "px01.vc.example.com")
        XCTAssertEqual(task.query.serviceType, kDNSServiceType_A)
    }
}

// MARK: - Mocks

private final class DNSLookupTaskMock: DNSLookupTaskProtocol {
    enum Step: Hashable {
        case prepare(flags: DNSServiceFlags)
        case start
        case cancel
    }

    var startDelay: TimeInterval = 0
    var query: DNSLookupQuery!
    var resultFlags: DNSServiceFlags = 0
    var result = [Data]()
    var preparationErrorCode: DNSServiceErrorType = Int32(kDNSServiceErr_NoError)
    var processingErrorCode: DNSServiceErrorType = Int32(kDNSServiceErr_NoError)

    private(set) var steps = [Step]()
    private var startTask: Task<DNSServiceErrorType, Never>?

    func prepare(withFlags flags: DNSServiceFlags) -> DNSServiceErrorType {
        steps.append(.prepare(flags: flags))
        return preparationErrorCode
    }

    func start() async -> DNSServiceErrorType {
        steps.append(.start)

        let startTask = Task<DNSServiceErrorType, Never> {
            try? await Task.sleep(seconds: startDelay)

            for data in result {
                query?.handler(
                    nil,
                    resultFlags,
                    0,
                    Int32(kDNSServiceErr_NoError),
                    nil,
                    0,
                    0,
                    UInt16(data.count),
                    [UInt8](data),
                    0,
                    &query.result
                )
            }

            return processingErrorCode
        }

        self.startTask = startTask

        return await startTask.value
    }

    func cancel() {
        startTask?.cancel()
        steps.append(.cancel)
    }
}
