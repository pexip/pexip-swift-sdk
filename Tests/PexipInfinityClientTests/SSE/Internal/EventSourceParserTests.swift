import XCTest
@testable import PexipInfinityClient

final class EventSourceParserTests: XCTestCase {
    private var parser: EventSourceParser!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        parser = EventSourceParser()
    }

    // MARK: - Stream parsing

    /// Test samples from
    /// https://html.spec.whatwg.org/multipage/server-sent-events.html#parsing-an-event-stream
    func testEventsFromDataWithStreamSample1() throws {
        let string = """
        data: YHOO
        data: +2
        data: 10


        """
        let data = try XCTUnwrap(string.data(using: .utf8))
        let events = parser.events(from: data)

        XCTAssertEqual(events.count, 1)

        let event = events[0]
        XCTAssertNil(event.id)
        XCTAssertNil(event.name)
        XCTAssertNil(event.retry)
        XCTAssertEqual(event.data, "YHOO\n+2\n10")
    }

    func testEventsFromDataWithStreamSample2() throws {
        let string = """
        : test stream

        data: first event
        id: 1

        data:second event
        id

        data:  third event

        """
        let data = try XCTUnwrap(string.data(using: .utf8))
        let events = parser.events(from: data)

        XCTAssertEqual(events.count, 2)

        let event1 = events[0]
        XCTAssertEqual(event1.id, "1")
        XCTAssertNil(event1.name)
        XCTAssertEqual(event1.data, "first event")
        XCTAssertNil(event1.retry)

        let event2 = events[1]
        XCTAssertEqual(event2.id, "")
        XCTAssertNil(event2.name)
        XCTAssertEqual(event2.data, "second event")
        XCTAssertNil(event2.retry)
    }

    func testEventsFromDataWithStreamSample3() throws {
        let string = """
        data

        data
        data

        data:


        """
        let data = try XCTUnwrap(string.data(using: .utf8))
        let events = parser.events(from: data)

        XCTAssertEqual(events.count, 3)

        let event1 = events[0]
        XCTAssertNil(event1.id)
        XCTAssertNil(event1.name)
        XCTAssertEqual(event1.data, "")
        XCTAssertNil(event1.retry)

        let event2 = events[1]
        XCTAssertNil(event2.id)
        XCTAssertNil(event2.name)
        XCTAssertEqual(event2.data, "\n")
        XCTAssertNil(event2.retry)

        let event3 = events[2]
        XCTAssertNil(event3.id)
        XCTAssertNil(event3.name)
        XCTAssertEqual(event3.data, "")
        XCTAssertNil(event3.retry)
    }

    func testEventsFromDataWithStreamSample4() throws {
        let string = """
        data:test

        data: test


        """
        let data = try XCTUnwrap(string.data(using: .utf8))
        let events = parser.events(from: data)

        XCTAssertEqual(events.count, 2)

        let event1 = events[0]
        let event2 = events[1]

        XCTAssertNil(event1.id)
        XCTAssertNil(event1.name)
        XCTAssertEqual(event1.data, "test")
        XCTAssertNil(event1.retry)

        XCTAssertEqual(event1, event2)
    }

    func testEventsFromDataWithCustomFields() throws {
        let string = """
        field: value
        data: test


        """
        let data = try XCTUnwrap(string.data(using: .utf8))
        let events = parser.events(from: data)

        XCTAssertEqual(events.count, 1)

        let event = events[0]

        XCTAssertNil(event.id)
        XCTAssertNil(event.name)
        XCTAssertEqual(event.data, "test")
        XCTAssertNil(event.retry)
    }

    func testClear() throws {
        let string = """
        data: test

        """
        let data = try XCTUnwrap(string.data(using: .utf8))
        let events = parser.events(from: data)

        XCTAssertTrue(events.isEmpty)
        XCTAssertEqual(parser.bufferString, string)

        parser.clear()
        XCTAssertEqual(parser.bufferString, String(data: Data(), encoding: .utf8))
    }

    // MARK: - Event parsing

    func testEventFromString() {
        let string = """
        id: 1
        event: test
        data: data1
        data: data2
        retry: 2000
        """
        let event = EventSourceParser.event(from: string)

        XCTAssertEqual(event?.id, "1")
        XCTAssertEqual(event?.name, "test")
        XCTAssertEqual(event?.data, "data1\ndata2")
        XCTAssertEqual(event?.retry, "2000")
    }

    func testEventFromStringWithComment() {
        XCTAssertNil(EventSourceParser.event(from: ":comment"))
        XCTAssertNil(EventSourceParser.event(from: ": comment"))
        XCTAssertNil(EventSourceParser.event(from: ": comment : comment"))
    }

    func testEventFromStringWithNoId() {
        let string = """
        event: test
        data: first event
        """
        let event = EventSourceParser.event(from: string)

        XCTAssertNil(event?.id)
        XCTAssertEqual(event?.name, "test")
        XCTAssertEqual(event?.data, "first event")
        XCTAssertNil(event?.retry)
    }

    func testEventFromStringWithData() {
        let string = """
        id: 1
        event: test
        """
        let event = EventSourceParser.event(from: string)

        XCTAssertEqual(event?.id, "1")
        XCTAssertEqual(event?.name, "test")
        XCTAssertNil(event?.data)
        XCTAssertNil(event?.retry)
    }

    func testEventFromStringWithEmptyFields() {
        let string = """
        id
        data
        data
        data
        event
        """
        let event = EventSourceParser.event(from: string)

        XCTAssertEqual(event?.id, "")
        XCTAssertNil(event?.name)
        XCTAssertEqual(event?.data, "\n\n")
        XCTAssertNil(event?.retry)
    }
}
