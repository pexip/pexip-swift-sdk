//
// Copyright 2022 Pexip AS
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import dnssd

// MARK: - Protocol

protocol DNSLookupTaskProtocol {
    func prepare(withFlags flags: DNSServiceFlags) -> DNSServiceErrorType
    func start() async -> DNSServiceErrorType
    func cancel()
}

// MARK: - Implementation

struct DNSLookupTask: DNSLookupTaskProtocol {
    let query: DNSLookupQuery
    private let sdRef: UnsafeMutablePointer<OpaquePointer?> = .allocate(
        capacity: MemoryLayout<OpaquePointer>.size
    )

    func prepare(withFlags flags: DNSServiceFlags) -> DNSServiceErrorType {
        DNSServiceQueryRecord(
            sdRef,
            flags,
            0,
            query.domain,
            UInt16(query.serviceType),
            UInt16(kDNSServiceClass_IN),
            query.handler,
            &query.result
        )
    }

    func start() async -> DNSServiceErrorType {
        DNSServiceProcessResult(sdRef.pointee)
    }

    func cancel() {
        DNSServiceRefDeallocate(sdRef.pointee)
    }
}
