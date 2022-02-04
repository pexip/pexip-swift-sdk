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

        client = DNSLookupClient(timeout: 0.1, makeLookupTask: { query in
            task.query = query
            return task
        })
    }

    // MARK: - Tests

    func testInit() {
        // Default timeout
        XCTAssertEqual(DNSLookupClient().timeout, 5)
        // Custom timeout
        XCTAssertEqual(DNSLookupClient(timeout: 10).timeout, 10)
    }

    func testResolveSRVRecords() async throws {
        let root = SRVRecord.Stub.root
        let record = SRVRecord.Stub.default

        task.result = [root.data, record.data]

        let records = try await client.resolveSRVRecords(
            service: "h323cs",
            proto: "tcp",
            name: "vc.example.com"
        )

        XCTAssertEqual(task.steps, [.prepare, .start, .cancel])
        XCTAssertEqual(task.query.domain, "_h323cs._tcp.vc.example.com")
        XCTAssertEqual(task.query.serviceType, kDNSServiceType_SRV)
        // Sorted records
        XCTAssertEqual(records, [record.instance, root.instance])
    }

    func testResolveSRVRecordsWithRootDomain() async throws {
        let record = SRVRecord.Stub.root
        task.result = [record.data]

        let records = try await client.resolveSRVRecords(
            service: "h323cs",
            proto: "tcp",
            name: "vc.example.com"
        )

        XCTAssertEqual(task.steps, [.prepare, .start, .cancel])
        XCTAssertEqual(task.query.domain, "_h323cs._tcp.vc.example.com")
        XCTAssertEqual(task.query.serviceType, kDNSServiceType_SRV)
        XCTAssertTrue(records.isEmpty)
    }

    func testResolveSRVRecordsWithInvalidData() async throws {
        task.result = [try XCTUnwrap("test".data(using: .utf8))]

        do {
            _ = try await client.resolveSRVRecords(
                service: "h323cs",
                proto: "tcp",
                name: "vc.example.com"
            )
            XCTFail("Should fail with error")
        } catch {
            XCTAssertTrue(error is SRVRecordError)
        }

        XCTAssertEqual(task.steps, [.prepare, .start, .cancel])
        XCTAssertEqual(task.query.domain, "_h323cs._tcp.vc.example.com")
        XCTAssertEqual(task.query.serviceType, kDNSServiceType_SRV)
    }

    func testResolveSRVRecordsWithErrorInPreparation() async throws {
        task.preparationErrorCode = Int32(kDNSServiceErr_ServiceNotRunning)

        do {
            _ = try await client.resolveSRVRecords(
                service: "h323cs",
                proto: "tcp",
                name: "vc.example.com"
            )
            XCTFail("Should fail with error")
        } catch {
            XCTAssertEqual(
                error as? DNSLookupError,
                .lookupFailed(code: task.preparationErrorCode)
            )
        }

        XCTAssertEqual(task.steps, [.prepare, .cancel])
        XCTAssertEqual(task.query.domain, "_h323cs._tcp.vc.example.com")
        XCTAssertEqual(task.query.serviceType, kDNSServiceType_SRV)
    }

    func testResolveSRVRecordsWithErrorInProcessing() async throws {
        task.processingErrorCode = Int32(kDNSServiceErr_NotPermitted)

        do {
            _ = try await client.resolveSRVRecords(
                service: "h323cs",
                proto: "tcp",
                name: "vc.example.com"
            )
            XCTFail("Should fail with error")
        } catch {
            XCTAssertEqual(
                error as? DNSLookupError,
                .lookupFailed(code: task.processingErrorCode)
            )
        }

        XCTAssertEqual(task.steps, [.prepare, .start, .cancel])
        XCTAssertEqual(task.query.domain, "_h323cs._tcp.vc.example.com")
        XCTAssertEqual(task.query.serviceType, kDNSServiceType_SRV)
    }

    func testResolveSRVRecordsWithTimeoutError() async throws {
        task.startDelay = 10

        do {
            _ = try await client.resolveSRVRecords(
                service: "h323cs",
                proto: "tcp",
                name: "vc.example.com"
            )
            XCTFail("Should fail with error")
        } catch {
            XCTAssertEqual(error as? DNSLookupError, .timeout)
        }

        XCTAssertEqual(task.steps, [.prepare, .start, .cancel])
        XCTAssertEqual(task.query.domain, "_h323cs._tcp.vc.example.com")
        XCTAssertEqual(task.query.serviceType, kDNSServiceType_SRV)
    }

    func testResolveARecords() async throws {
        let record = ARecord.Stub.default
        task.result = [record.data]

        let records = try await client.resolveARecords(
            for: "px01.vc.example.com"
        )

        XCTAssertEqual(task.steps, [.prepare, .start, .cancel])
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

        XCTAssertEqual(task.steps, [.prepare, .cancel])
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

        XCTAssertEqual(task.steps, [.prepare, .start, .cancel])
        XCTAssertEqual(task.query.domain, "px01.vc.example.com")
        XCTAssertEqual(task.query.serviceType, kDNSServiceType_A)
    }
}

// MARK: - Mocks

private final class DNSLookupTaskMock: DNSLookupTaskProtocol {
    enum Step {
        case prepare
        case start
        case cancel
    }

    var startDelay: TimeInterval = 0
    var query: DNSLookupQuery!
    var result = [Data]()
    var preparationErrorCode: DNSServiceErrorType = Int32(kDNSServiceErr_NoError)
    var processingErrorCode: DNSServiceErrorType = Int32(kDNSServiceErr_NoError)

    private(set) var steps = [Step]()
    private var startTask: Task<DNSServiceErrorType, Never>?

    func prepare() -> DNSServiceErrorType {
        steps.append(.prepare)
        return preparationErrorCode
    }

    func start() async -> DNSServiceErrorType {
        steps.append(.start)

        let startTask = Task<DNSServiceErrorType, Never> {
            try? await Task.sleep(seconds: startDelay)

            for data in result {
                query?.handler(
                    nil,
                    0,
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
