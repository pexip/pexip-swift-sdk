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

@frozen
public enum DNSLookupError: LocalizedError, CustomStringConvertible, Hashable {
    case timeout
    case lookupFailed(code: Int32)
    case responseNotSecuredWithDNSSEC
    case invalidSRVRecordData
    case invalidARecordData

    public var description: String {
        switch self {
        case .timeout:
            return "DNS lookup timeout"
        case .lookupFailed(let code):
            return "DNS lookup failed with error, code: \(code)"
        case .responseNotSecuredWithDNSSEC:
            return "DNS lookup response is not secured with DNSSEC"
        case .invalidSRVRecordData:
            return "Invalid SRV record data received"
        case .invalidARecordData:
            return "Invalid A record data received"
        }
    }

    public var errorDescription: String? {
        description
    }
}
