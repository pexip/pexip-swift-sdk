import XCTest
@testable import PexipVideo

final class EventSourceTests: XCTestCase {
    private let url = URL(string: "https://test.example.org")!

    // MARK: - Tests
        
    func testEventStream() async throws {
        // 1. Prepare
        let stream = EventSource.eventStream(
            withRequest: URLRequest(url: url, httpMethod: .GET),
            lastEventId: "11",
            urlProtocolClasses: [URLProtocolMock.self]
        )
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
        
        // 2. Receive events from the stream
        do {
            for try await event in stream {
                receivedEvents.append(event)
            }
        } catch let error as EventSourceError {
            XCTAssertEqual(error.response?.url, url)
            XCTAssertEqual(error.response?.statusCode, 200)
            XCTAssertTrue(error.response?.allHeaderFields.isEmpty == true)
            XCTAssertNil(error.dataStreamError)
        }
        
        // 3. Assert
        XCTAssertEqual(
            createdRequest?.value(forHTTPHeaderField: "Last-Event-Id"),
            "11"
        )
        
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
    }
    
    func testEventStreamWithErrors() async throws {
        // 1. Prepare
        let stream = EventSource.eventStream(
            withRequest: URLRequest(url: url, httpMethod: .GET),
            lastEventId: nil,
            urlProtocolClasses: [URLProtocolMock.self]
        )
        var createdRequest: URLRequest?
        var receivedEvents = [MessageEvent]()
        
        URLProtocolMock.makeResponse = { request in
            createdRequest = request
            throw URLError(.badURL)
        }
        
        // 2. Receive events from the stream
        do {
            for try await event in stream {
                receivedEvents.append(event)
            }
        } catch let error as EventSourceError {
            XCTAssertNil(error.response)
            XCTAssertEqual((error.dataStreamError as? URLError)?.code, .badURL)
        }
        
        // 3. Assert
        XCTAssertNil(createdRequest?.value(forHTTPHeaderField: "Last-Event-Id"))
        XCTAssertTrue(receivedEvents.isEmpty)
    }
}
