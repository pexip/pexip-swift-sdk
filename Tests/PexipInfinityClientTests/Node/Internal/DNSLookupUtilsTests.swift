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

import XCTest
@testable import PexipInfinityClient

final class DNSLookupUtilsTests: XCTestCase {
    func testSortSRVRecords() {
        let records: [SRVRecord] = [
            SRVRecord(priority: 1, weight: 2, port: 1720, target: "px01.vc.example.com"),
            SRVRecord(priority: 2, weight: 0, port: 1720, target: "px02.vc.example.com"),
            SRVRecord(priority: 1, weight: 1, port: 1720, target: "px03.vc.example.com"),
            SRVRecord(priority: 2, weight: 0, port: 1720, target: "px04.vc.example.com"),
            SRVRecord(priority: 1, weight: 2, port: 1720, target: "px05.vc.example.com"),
            SRVRecord(priority: 0, weight: 2, port: 1720, target: "px06.vc.example.com"),
            SRVRecord(priority: 3, weight: 1, port: 1720, target: "px08.vc.example.com"),
            SRVRecord(priority: 1, weight: 3, port: 1720, target: "px07.vc.example.com")
        ]
        let sortedRecords = DNSLookupUtils.sortSRVRecords(records)

        XCTAssertEqual(sortedRecords.count, records.count)
        XCTAssertEqual(sortedRecords[0], records[5])
        XCTAssertTrue(records.filter { $0.priority == 1 }.contains(sortedRecords[1]))
        XCTAssertTrue(records.filter { $0.priority == 1 }.contains(sortedRecords[2]))
        XCTAssertTrue(records.filter { $0.priority == 1 }.contains(sortedRecords[3]))
        XCTAssertTrue(records.filter { $0.priority == 1 }.contains(sortedRecords[4]))
        XCTAssertTrue(records.filter { $0.priority == 2 }.contains(sortedRecords[5]))
        XCTAssertTrue(records.filter { $0.priority == 2 }.contains(sortedRecords[6]))
        XCTAssertEqual(sortedRecords[7], records[6])
    }

    func testSortSRVRecordsWithRootDomain() {
        let records = [SRVRecord.Stub.root.instance]
        let sortedRecords = DNSLookupUtils.sortSRVRecords(records)
        XCTAssertTrue(sortedRecords.isEmpty)
    }
}
