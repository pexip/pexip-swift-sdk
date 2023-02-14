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

import Foundation
import dnssd

/// An A record maps a domain name to the IP address (Version 4) of the computer hosting the domain
struct ARecord: Hashable {
    /// The IPv4 address the A record points to.
    let ipv4Address: String
}

// MARK: - DNSRecord

extension ARecord: DNSRecord {
    static var serviceType = kDNSServiceType_A

    init(data: Data) throws {
        guard data.count == 4 else {
            throw DNSLookupError.invalidARecordData
        }

        ipv4Address = "\(data[0]).\(data[1]).\(data[2]).\(data[3])"
    }
}
