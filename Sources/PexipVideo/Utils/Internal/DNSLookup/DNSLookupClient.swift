import Foundation
import dnssd

// MARK: - Protocol

protocol DNSLookupClientProtocol {
    func resolveSRVRecords(for name: String, dnssec: Bool) async throws -> [SRVRecord]
    func resolveARecords(for name: String, dnssec: Bool) async throws -> [ARecord]
}

// MARK: - Implementation

final class DNSLookupClient: DNSLookupClientProtocol {
    typealias DNSLookupTaskFactory = (DNSLookupQuery) -> DNSLookupTaskProtocol

    let timeout: TimeInterval
    let makeLookupTask: DNSLookupTaskFactory

    // MARK: - Init

    init(
        timeout: TimeInterval = 5,
        makeLookupTask: @escaping DNSLookupTaskFactory = {
            DNSLookupTask(query: $0)
        }
    ) {
        self.timeout = timeout
        self.makeLookupTask = makeLookupTask
    }

    // MARK: - Lookup

    func resolveSRVRecords(
        for name: String,
        dnssec: Bool = false
    ) async throws -> [SRVRecord] {
        let records: [SRVRecord] = try await resolveRecords(
            forName: name,
            dnssec: dnssec
        )

        // RFC 2782: if there is precisely one SRV RR, and its Target is "."
        // (the root domain), abort."
        if records.first?.target == ".", records.count == 1 {
            return []
        }

        return records.sorted()
    }

    func resolveARecords(
        for name: String,
        dnssec: Bool = false
    ) async throws -> [ARecord] {
        try await resolveRecords(forName: name, dnssec: dnssec)
    }

    // MARK: - Private

    private func resolveRecords<T: DNSRecord>(
        forName name: String,
        dnssec: Bool
    ) async throws -> [T] {
        let task = Task { () -> [T] in
            let query = DNSLookupQuery(
                domain: name,
                serviceType: T.serviceType,
                handler: DNSLookupClient.queryHandler
            )

            var flags: DNSServiceFlags = 0
            if dnssec {
                flags |= kDNSServiceFlagsValidate
            }

            let lookupTask = makeLookupTask(query)
            try await lookupTask.waitForResults(
                withTimeout: timeout,
                flags: flags
            )

            let isSecure = query.result.flags & kDNSServiceFlagsSecure == kDNSServiceFlagsSecure

            if dnssec && !isSecure {
                throw DNSLookupError.responseNotSecuredWithDNSSEC
            }

            return try query.result.records.compactMap(T.init)
        }

        return try await task.value
    }

    // swiftlint:disable closure_parameter_position
    private static let queryHandler: DNSServiceQueryRecordReply = {
        _, flags, _, _, _, _, _, length, bytes, _, context in

        guard let context = context?.assumingMemoryBound(
            to: DNSLookupQuery.Result.self
        ).pointee else {
            return
        }

        context.flags = flags

        if let bytes = bytes, length > 0 {
            context.records.append(Data(bytes: bytes, count: Int(length)))
        }
    }
}

// MARK: - Private extensions

private extension DNSLookupTaskProtocol {
    func waitForResults(
        withTimeout timeout: TimeInterval,
        flags: DNSServiceFlags
    ) async throws {
        let isTimeoutReached = Isolated(value: false)

        let timeoutTask = Task<Void, Error> {
            try await Task.sleep(seconds: timeout)
            await isTimeoutReached.setValue(true)
            cancel()
        }

        defer {
            Task {
                if await !isTimeoutReached.value {
                    timeoutTask.cancel()
                    cancel()
                }
            }
        }

        var errorCode = prepare(withFlags: flags)

        guard errorCode == kDNSServiceErr_NoError else {
            throw DNSLookupError.lookupFailed(code: errorCode)
        }

        errorCode = await start()

        guard await !isTimeoutReached.value else {
            throw DNSLookupError.timeout
        }

        guard errorCode == kDNSServiceErr_NoError else {
            throw DNSLookupError.lookupFailed(code: errorCode)
        }
    }
}

// MARK: - Private types

actor Isolated<T> {
    var value: T

    init(value: T) {
        self.value = value
    }

    func setValue(_ value: T) {
        self.value = value
    }
}
