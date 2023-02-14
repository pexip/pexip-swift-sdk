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

#if os(iOS)

import XCTest
import CoreVideo
import CoreMedia
@testable import PexipScreenCapture

final class BroadcastNotificationCenterTests: XCTestCase {
    private let center = BroadcastNotificationCenter.default
    private var testObserver: ObserverMock!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        testObserver = ObserverMock()
    }

    override func tearDown() {
        center.removeAll()
        super.tearDown()
    }

    // MARK: - Tests

    func testAddObserver() {
        XCTAssertTrue(center.observations.isEmpty)

        center.addObserver(self, for: .senderStarted, using: {})
        center.addObserver(self, for: .senderFinished, using: {})

        XCTAssertEqual(center.observations.count, 2)

        XCTAssertTrue(center.observations[0].observer === self)
        XCTAssertEqual(center.observations[0].notification, .senderStarted)

        XCTAssertTrue(center.observations[1].observer === self)
        XCTAssertEqual(center.observations[1].notification, .senderFinished)
    }

    func testAddObserverTwice() {
        XCTAssertTrue(center.observations.isEmpty)

        let expectation = self.expectation(description: "Notification callback")
        var result = 0

        center.addObserver(self, for: .senderStarted, using: {
            result = 1
        })

        center.addObserver(self, for: .senderStarted, using: {
            result = 2
            expectation.fulfill()
        })

        center.post(.senderStarted)

        wait(for: [expectation], timeout: 0.1)

        XCTAssertEqual(center.observations.count, 1)
        XCTAssertEqual(center.observations[0].notification, .senderStarted)
        XCTAssertTrue(center.observations[0].observer === self)
        XCTAssertEqual(result, 2)
    }

    func testRemoveObserver() {
        XCTAssertTrue(center.observations.isEmpty)

        center.addObserver(self, for: .senderStarted, using: {})
        center.addObserver(self, for: .senderFinished, using: {})

        XCTAssertEqual(center.observations.count, 2)

        center.removeObserver(self)

        XCTAssertTrue(center.observations.isEmpty)
    }

    func testRemoveObserverWithMultipleObservers() {
        XCTAssertTrue(center.observations.isEmpty)

        center.addObserver(self, for: .senderStarted, using: {})
        center.addObserver(self, for: .senderFinished, using: {})
        center.addObserver(testObserver, for: .senderStarted, using: {})
        center.addObserver(testObserver, for: .senderFinished, using: {})

        XCTAssertEqual(center.observations.count, 4)

        center.removeObserver(self)

        XCTAssertEqual(center.observations.count, 2)

        XCTAssertEqual(center.observations[0].notification, .senderStarted)
        XCTAssertTrue(center.observations[0].observer === testObserver)

        XCTAssertEqual(center.observations[1].notification, .senderFinished)
        XCTAssertTrue(center.observations[1].observer === testObserver)
    }

    func testRemoveDeallocatedObserver() {
        XCTAssertTrue(center.observations.isEmpty)

        center.addObserver(self, for: .senderStarted, using: {})
        center.addObserver(testObserver, for: .senderStarted, using: {})

        XCTAssertEqual(center.observations.count, 2)

        testObserver = nil
        center.removeObserver(self)

        XCTAssertTrue(center.observations.isEmpty)
    }

    func testRemoveObserverForNotification() {
        XCTAssertTrue(center.observations.isEmpty)

        center.addObserver(self, for: .senderStarted, using: {})
        center.addObserver(self, for: .senderFinished, using: {})

        XCTAssertEqual(center.observations.count, 2)

        center.removeObserver(self, for: .senderStarted)

        XCTAssertEqual(center.observations.count, 1)
        XCTAssertEqual(center.observations[0].notification, .senderFinished)
        XCTAssertTrue(center.observations[0].observer === self)
    }

    func testRemoveObserverForNotificationWithMultipleObservers() {
        XCTAssertTrue(center.observations.isEmpty)

        center.addObserver(self, for: .senderStarted, using: {})
        center.addObserver(self, for: .senderFinished, using: {})
        center.addObserver(testObserver, for: .senderStarted, using: {})
        center.addObserver(testObserver, for: .senderFinished, using: {})

        XCTAssertEqual(center.observations.count, 4)

        center.removeObserver(self, for: .senderStarted)

        XCTAssertEqual(center.observations.count, 3)

        XCTAssertEqual(center.observations[0].notification, .senderFinished)
        XCTAssertTrue(center.observations[0].observer === self)

        XCTAssertEqual(center.observations[1].notification, .senderStarted)
        XCTAssertTrue(center.observations[1].observer === testObserver)

        XCTAssertEqual(center.observations[2].notification, .senderFinished)
        XCTAssertTrue(center.observations[2].observer === testObserver)
    }

    func testRemoveAll() {
        XCTAssertTrue(center.observations.isEmpty)

        center.addObserver(self, for: .senderStarted, using: {})
        center.addObserver(testObserver, for: .senderStarted, using: {})

        XCTAssertEqual(center.observations.count, 2)

        center.removeAll()

        XCTAssertTrue(center.observations.isEmpty)
    }

    func testPost() {
        XCTAssertTrue(center.observations.isEmpty)

        let expectation1 = self.expectation(description: "Expectation 1")
        center.addObserver(self, for: .senderStarted, using: {
            expectation1.fulfill()
        })

        let expectation2 = self.expectation(description: "Expectation 2")
        center.addObserver(testObserver, for: .senderStarted, using: {
            expectation2.fulfill()
        })

        let expectation3 = self.expectation(description: "Expectation 3")
        center.addObserver(self, for: .senderFinished, using: {
            expectation3.fulfill()
        })

        let expectation4 = self.expectation(description: "Expectation 4")
        center.addObserver(testObserver, for: .senderFinished, using: {
            expectation4.fulfill()
        })

        center.post(.senderStarted)
        center.post(.senderFinished)

        wait(for: [expectation1, expectation2, expectation3, expectation4], timeout: 0.1)
    }
}

// MARK: - Mocks

private final class ObserverMock {}

#endif
