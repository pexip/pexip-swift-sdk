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

final class DNSLookupQuery {
    final class Result {
        var records = [Data]()
        var flags: DNSServiceFlags = 0
    }

    let domain: String
    let serviceType: Int
    let handler: DNSServiceQueryRecordReply
    var result = Result()

    // MARK: - Init

    init(
        domain: String,
        serviceType: Int,
        handler: @escaping DNSServiceQueryRecordReply
    ) {
        self.domain = domain
        self.serviceType = serviceType
        self.handler = handler
    }
}
