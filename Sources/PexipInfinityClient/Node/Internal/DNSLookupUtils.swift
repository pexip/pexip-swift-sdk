//
// Copyright 2023 Pexip AS
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

enum DNSLookupUtils {
    /// Sorting SRV records according to RFC 2782 specs https://www.rfc-editor.org/rfc/rfc2782
    static func sortSRVRecords(_ records: [SRVRecord]) -> [SRVRecord] {
        // RFC 2782: if there is precisely one SRV RR, and its Target is "."
        // (the root domain), abort."
        if records.count == 1 && records[0].target == "." {
            return []
        }

        let buckets = Dictionary(grouping: records, by: { $0.priority })
        let sortedBuckets = buckets.sorted(by: { $0.key < $1.key })

        var sortedRecords = [SRVRecord]()

        for (_, var bucket) in sortedBuckets {
            while !bucket.isEmpty {
                var totals = [Int]()
                var bucketWeightSum: Int = 0
                let zeroWeight: Int = bucket.contains { $0.weight > 0 } ? 0 : 1

                for record in bucket {
                    bucketWeightSum += Int(record.weight) + zeroWeight
                    totals.append(bucketWeightSum)
                }

                var index = 0

                if bucketWeightSum == 0 {
                    index = Int.random(in: 0..<bucket.count)
                } else {
                    let random = Double.random(in: 0.0..<Double(bucketWeightSum))
                    index = totals.firstIndex { random < Double($0) } ?? totals.count - 1
                }

                sortedRecords.append(bucket.remove(at: index))
            }
        }

        return sortedRecords
    }
}
