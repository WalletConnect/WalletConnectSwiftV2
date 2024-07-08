import Foundation
import XCTest
@testable import Events

class EventsCollectorTests: XCTestCase {

    var mockStorage: MockEventStorage!
    var eventsCollector: EventsCollector!

    override func setUp() {
        super.setUp()
        mockStorage = MockEventStorage()
        eventsCollector = EventsCollector(storage: mockStorage, logger: ConsoleLoggerMock())
    }

    override func tearDown() {
        eventsCollector = nil
        mockStorage = nil
        super.tearDown()
    }

    func testStartTrace() {
        eventsCollector.startTrace(topic: "test_topic")
        XCTAssertEqual(eventsCollector.topic, "test_topic")
        XCTAssertEqual(eventsCollector.trace.count, 0)
    }

    func testSaveEvent() {
        eventsCollector.startTrace(topic: "test_topic")
        eventsCollector.saveEvent(PairingExecutionTraceEvents.pairingStarted)

        XCTAssertEqual(eventsCollector.trace, ["pairing_started"])
        XCTAssertEqual(mockStorage.savedEvents.count, 0)
    }

    func testSaveErrorEvent() {
        eventsCollector.startTrace(topic: "test_topic")
        eventsCollector.saveEvent(PairingExecutionTraceEvents.pairingStarted)
        eventsCollector.saveEvent(PairingTraceErrorEvents.noInternetConnection)

        XCTAssertEqual(mockStorage.savedEvents.count, 1)
        let savedEvent = mockStorage.savedEvents.first
        XCTAssertNotNil(savedEvent)
        XCTAssertEqual(savedEvent?.props.type, "no_internet_connection")
        XCTAssertEqual(savedEvent?.props.properties?.topic, "test_topic")
        XCTAssertEqual(savedEvent?.props.properties?.trace, ["pairing_started", "no_internet_connection"])
        XCTAssertNil(eventsCollector.topic)
        XCTAssertEqual(eventsCollector.trace.count, 0)
    }
}
