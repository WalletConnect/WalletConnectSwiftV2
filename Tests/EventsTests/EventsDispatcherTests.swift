import XCTest
@testable import Events

class EventsDispatcherTests: XCTestCase {
    var mockNetworkingService: MockNetworkingService!
    var eventsDispatcher: EventsDispatcher!
    let events = [TraceEvent(eventId: UUID().uuidString, bundleId: "com.wallet.example", timestamp: Int64(Date().timeIntervalSince1970 * 1000), props: TraceEvent.Props(event: "ERROR", type: "test_error", properties: TraceEvent.Properties(topic: "test_topic", trace: ["test_trace"])))]

    override func setUp() {
        super.setUp()
        mockNetworkingService = MockNetworkingService()
        let retryPolicy = RetryPolicy(maxAttempts: 3, initialDelay: 1, multiplier: 1.5, delayOverride: 0.001)
        eventsDispatcher = EventsDispatcher(networkingService: mockNetworkingService, retryPolicy: retryPolicy)
    }

    override func tearDown() {
        eventsDispatcher = nil
        mockNetworkingService = nil
        super.tearDown()
    }

    func testRetrySuccess() async throws {
        mockNetworkingService.shouldFail = true
        do {
            _ = try await eventsDispatcher.executeWithRetry(events: events)
            XCTFail("Expected to throw an error")
        } catch {
            XCTAssertEqual(mockNetworkingService.attemptCount, 3)
        }
    }

    func testRetryFailure() async throws {
        mockNetworkingService.shouldFail = false
        let result = try await eventsDispatcher.executeWithRetry(events: events)
        XCTAssertEqual(result, true)
        XCTAssertEqual(mockNetworkingService.attemptCount, 1)
    }
}
