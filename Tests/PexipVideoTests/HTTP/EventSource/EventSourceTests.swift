import XCTest
@testable import PexipVideo

final class EventSourceTests: XCTestCase {
    private var eventSource: EventSource!
    private let url = URL(string: "https://test.example.org")!

    // MARK: - Setup
    
    override func setUp() {
        eventSource = EventSource(
            url: url,
            headers: { [HTTPHeader(name: "header", value: "value")] },
            protocolClasses: [URLProtocolMock.self]
        )
    }
    
    // MARK: - Tests

    func testInit() {
        XCTAssertEqual(url, eventSource.url)
        XCTAssertEqual(eventSource.state, .closed)
    }
    
    func testOnOpen() throws {
        let expectation = self.expectation(description: "onOpen callback")
        var createdRequest: URLRequest?
        let string = ": test stream"
        let data = try XCTUnwrap(string.data(using: .utf8))
        
        URLProtocolMock.makeResponse = { request in
            createdRequest = request
            return .init(statusCode: 200, data: data)
        }
        
        eventSource.onOpen = { [weak eventSource] in
            XCTAssertEqual(eventSource?.state, .open)
            expectation.fulfill()
        }
        
        // 1. Connect and wait for events
        eventSource.connect(lastEventId: "11")
        XCTAssertEqual(eventSource.state, .connecting)
        
        wait(for: [expectation], timeout: 0.1)
                
        // 2. Test created request
        XCTAssertEqual(createdRequest?.url, url)
        XCTAssertEqual(
            createdRequest?.cachePolicy,
            .reloadIgnoringLocalAndRemoteCacheData
        )
        XCTAssertEqual(
            createdRequest?.timeoutInterval,
            TimeInterval(INT_MAX)
        )
        XCTAssertEqual(
            createdRequest?.value(forHTTPHeaderField: "Last-Event-Id"),
            "11"
        )
        XCTAssertEqual(
            createdRequest?.value(forHTTPHeaderField: "header"),
            "value"
        )
        XCTAssertEqual(
            createdRequest?.value(forHTTPHeaderField: "Accept"),
            "text/event-stream"
        )
        XCTAssertEqual(
            createdRequest?.value(forHTTPHeaderField: "Cache-Control"),
            "no-cache"
        )
        
        // 3. Disconnect
        eventSource.disconnect()
        XCTAssertEqual(eventSource.state, .closed)
    }

    func testOnMessage() throws {
        let expectation = self.expectation(description: "onMessage callback")
        var createdRequest: URLRequest?
        var receivedEvents = [MessageEvent]()
        let string = """
        : test stream

        data: first event
        id: 1

        data:second event
        event: test
        id: 22
        retry: 2000
        

        """
        let data = try XCTUnwrap(string.data(using: .utf8))
        
        URLProtocolMock.makeResponse = { request in
            createdRequest = request
            return .init(statusCode: 200, data: data)
        }
        
        eventSource.onMessage = { event in
            receivedEvents.append(event)
            
            if receivedEvents.count == 2 {
                expectation.fulfill()
            }
        }
        
        // 1. Connect and wait for events
        eventSource.connect()
        wait(for: [expectation], timeout: 0.1)

        // 2. Test created request
        XCTAssertNil(createdRequest?.value(forHTTPHeaderField: "Last-Event-Id"))
        
        // 3. Test received events
        XCTAssertEqual(receivedEvents.count, 2)
        
        let event1 = receivedEvents[0]
        XCTAssertEqual(event1.id, "1")
        XCTAssertNil(event1.name)
        XCTAssertEqual(event1.data, "first event")
        XCTAssertNil(event1.retry)

        let event2 = receivedEvents[1]
        XCTAssertEqual(event2.id, "22")
        XCTAssertEqual(event2.name, "test")
        XCTAssertEqual(event2.data, "second event")
        XCTAssertEqual(event2.retry, "2000")
        
        // Test reconnectionTime and lastEventId
        XCTAssertEqual(eventSource.reconnectionTime, 2)
        XCTAssertEqual(eventSource.lastEventId, "22")
    }
    
    func testEventListener() throws {
        let expectation = self.expectation(description: "Event listener")
        var receivedEventData: Data?
        let string = """
        data:first event
        event: test
        id

        
        """
        let data = try XCTUnwrap(string.data(using: .utf8))
        
        URLProtocolMock.makeResponse = { _ in
            return .init(statusCode: 200, data: data)
        }
        
        eventSource.addEventListener("test") { data in
            receivedEventData = data
            expectation.fulfill()
        }
        
        // 1. Connect and wait for events
        eventSource.connect()
        wait(for: [expectation], timeout: 0.1)

        // 2. Test received event
        XCTAssertEqual(receivedEventData, "first event".data(using: .utf8))
    }

    func testOnComplete() throws {
        let expectation = self.expectation(description: "onComplete callback")
        
        URLProtocolMock.makeResponse = { _ in
            throw URLError(.badURL)
        }
        
        eventSource.onComplete = { [weak eventSource] _, error in
            XCTAssertEqual((error as? URLError)?.code, .badURL)
            XCTAssertEqual(eventSource?.state, .closed)
            expectation.fulfill()
        }
        
        // Connect and wait for events
        eventSource.connect()
        wait(for: [expectation], timeout: 0.1)
    }
    
    func testReconnect() throws {
        let expectation = self.expectation(description: "Reconnect")
        let string = """
        data: event
        event: test
        retry: 10


        """
        let data = try XCTUnwrap(string.data(using: .utf8))
    
        // 1. Send event with retry = 0.01 seconds
        URLProtocolMock.makeResponse = { _ in
            .init(statusCode: 200, data: data)
        }
        
        // 2. Reconnect on complete
        eventSource.onComplete = { [weak eventSource] _, error in
            eventSource?.onComplete = nil
            eventSource?.onMessage = nil

            URLProtocolMock.makeResponse = { _ in
                .init(statusCode: 200, data: data)
            }
                        
            // Add event listener
            eventSource?.addEventListener("test") { data in
                XCTAssertEqual(data, "event".data(using: .utf8))
                expectation.fulfill()
            }
            
            // Reconnect in 0.01 seconds
            eventSource?.reconnect()
        }
        
        // Connect and wait for events
        eventSource.connect()
        wait(for: [expectation], timeout: 0.1)
    }
}
