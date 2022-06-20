#if os(iOS)

import XCTest
import CoreVideo
import CoreMedia
@testable import PexipMedia

final class BroadcastNotificationCenterTests: XCTestCase {
    private let center = BroadcastNotificationCenter.default
    private let testObserver = ObserverMock()

    // MARK: - Setup

    override func tearDown() {
        center.removeAll()
        super.tearDown()
    }

    // MARK: - Tests

    func testAddObserver() {
        XCTAssertTrue(center.observations.isEmpty)

        center.addObserver(self, for: .broadcastStarted, using: {})
        center.addObserver(self, for: .broadcastFinished, using: {})

        XCTAssertEqual(center.observations.count, 2)

        XCTAssertTrue(center.observations[0].observer === self)
        XCTAssertEqual(center.observations[0].notification, .broadcastStarted)

        XCTAssertTrue(center.observations[1].observer === self)
        XCTAssertEqual(center.observations[1].notification, .broadcastFinished)
    }

    func testAddObserverTwice() {
        XCTAssertTrue(center.observations.isEmpty)

        let expectation = self.expectation(description: "Notification callback")
        var result = 0

        center.addObserver(self, for: .broadcastStarted, using: {
            result = 1
        })

        center.addObserver(self, for: .broadcastStarted, using: {
            result = 2
            expectation.fulfill()
        })

        center.post(.broadcastStarted)

        wait(for: [expectation], timeout: 0.1)

        XCTAssertEqual(center.observations.count, 1)
        XCTAssertEqual(center.observations[0].notification, .broadcastStarted)
        XCTAssertTrue(center.observations[0].observer === self)
        XCTAssertEqual(result, 2)
    }

    func testRemoveObserver() {
        XCTAssertTrue(center.observations.isEmpty)

        center.addObserver(self, for: .broadcastStarted, using: {})
        center.addObserver(self, for: .broadcastFinished, using: {})

        XCTAssertEqual(center.observations.count, 2)

        center.removeObserver(self)

        XCTAssertTrue(center.observations.isEmpty)
    }

    func testRemoveObserverWithMultipleObservers() {
        XCTAssertTrue(center.observations.isEmpty)

        center.addObserver(self, for: .broadcastStarted, using: {})
        center.addObserver(self, for: .broadcastFinished, using: {})
        center.addObserver(testObserver, for: .broadcastStarted, using: {})
        center.addObserver(testObserver, for: .broadcastFinished, using: {})

        XCTAssertEqual(center.observations.count, 4)

        center.removeObserver(self)

        XCTAssertEqual(center.observations.count, 2)

        XCTAssertEqual(center.observations[0].notification, .broadcastStarted)
        XCTAssertTrue(center.observations[0].observer === testObserver)

        XCTAssertEqual(center.observations[1].notification, .broadcastFinished)
        XCTAssertTrue(center.observations[1].observer === testObserver)
    }

    func testRemoveObserverForNotification() {
        XCTAssertTrue(center.observations.isEmpty)

        center.addObserver(self, for: .broadcastStarted, using: {})
        center.addObserver(self, for: .broadcastFinished, using: {})

        XCTAssertEqual(center.observations.count, 2)

        center.removeObserver(self, for: .broadcastStarted)

        XCTAssertEqual(center.observations.count, 1)
        XCTAssertEqual(center.observations[0].notification, .broadcastFinished)
        XCTAssertTrue(center.observations[0].observer === self)
    }

    func testRemoveObserverForNotificationWithMultipleObservers() {
        XCTAssertTrue(center.observations.isEmpty)

        center.addObserver(self, for: .broadcastStarted, using: {})
        center.addObserver(self, for: .broadcastFinished, using: {})
        center.addObserver(testObserver, for: .broadcastStarted, using: {})
        center.addObserver(testObserver, for: .broadcastFinished, using: {})

        XCTAssertEqual(center.observations.count, 4)

        center.removeObserver(self, for: .broadcastStarted)

        XCTAssertEqual(center.observations.count, 3)

        XCTAssertEqual(center.observations[0].notification, .broadcastFinished)
        XCTAssertTrue(center.observations[0].observer === self)

        XCTAssertEqual(center.observations[1].notification, .broadcastStarted)
        XCTAssertTrue(center.observations[1].observer === testObserver)

        XCTAssertEqual(center.observations[2].notification, .broadcastFinished)
        XCTAssertTrue(center.observations[2].observer === testObserver)
    }

    func testRemoveAll() {
        XCTAssertTrue(center.observations.isEmpty)

        center.addObserver(self, for: .broadcastStarted, using: {})
        center.addObserver(testObserver, for: .broadcastStarted, using: {})

        XCTAssertEqual(center.observations.count, 2)

        center.removeAll()

        XCTAssertTrue(center.observations.isEmpty)
    }

    func testPost() {
        XCTAssertTrue(center.observations.isEmpty)

        let expectation1 = self.expectation(description: "Expectation 1")
        center.addObserver(self, for: .broadcastStarted, using: {
            expectation1.fulfill()
        })

        let expectation2 = self.expectation(description: "Expectation 2")
        center.addObserver(testObserver, for: .broadcastStarted, using: {
            expectation2.fulfill()
        })

        let expectation3 = self.expectation(description: "Expectation 3")
        center.addObserver(self, for: .broadcastFinished, using: {
            expectation3.fulfill()
        })

        let expectation4 = self.expectation(description: "Expectation 4")
        center.addObserver(testObserver, for: .broadcastFinished, using: {
            expectation4.fulfill()
        })

        center.post(.broadcastStarted)
        center.post(.broadcastFinished)

        wait(for: [expectation1, expectation2, expectation3, expectation4], timeout: 0.1)
    }
}

// MARK: - Mocks

private final class ObserverMock {}

#endif
