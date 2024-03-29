//
// Copyright 2022-2023 Pexip AS
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

/// A Service record (SRV record) is a specification of data in the Domain Name System
/// defining the location, i.e., the hostname and port number, of servers for specified services.
/// https://en.wikipedia.org/wiki/SRV_record
struct SRVRecord: Hashable {
    /// The priority of the target host, lower value means more preferred.
    let priority: UInt16
    /// A relative weight for records with the same priority, higher value means higher chance of getting picked.
    let weight: UInt16
    /// The TCP or UDP port on which the service is to be found.
    let port: UInt16
    /// The canonical hostname of the machine providing the service.
    let target: String
}

// MARK: - DNSRecord

extension SRVRecord: DNSRecord {
    static var serviceType = kDNSServiceType_SRV

    init(data: Data) throws {
        guard data.count > 6 else {
            throw DNSLookupError.invalidSRVRecordData
        }

        priority = UInt16(bigEndian: data[0...2].withUnsafeBytes { $0.load(as: UInt16.self) })
        weight = UInt16(bigEndian: data[2...4].withUnsafeBytes { $0.load(as: UInt16.self) })
        port = UInt16(bigEndian: data[4...6].withUnsafeBytes { $0.load(as: UInt16.self) })

        // A byte array of format [size][ascii bytes]...[null]
        var targetData = data.subdata(in: 6..<data.endIndex)
        var index = targetData.startIndex

        while index < targetData.endIndex {
            let size = Int(targetData[index])
            targetData[index] = UInt8(46) // Replace with "." (period, dot)
            index = index.advanced(by: size + 1)
        }

        // Drop first and last dots
        targetData = targetData.dropFirst().dropLast()
        target = String(data: targetData, encoding: .ascii) ?? ""
    }
}
