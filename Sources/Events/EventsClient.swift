import Foundation

public class EventsClient {
    private let eventsCollector: EventsCollector
    private let eventsDispatcher: EventsDispatcher
    private let logger: ConsoleLogging

    init(
        eventsCollector: EventsCollector,
        eventsDispatcher: EventsDispatcher,
        logger: ConsoleLogging
    ) {
        self.eventsCollector = eventsCollector
        self.eventsDispatcher = eventsDispatcher
        self.logger = logger
        Task { await sendStoredEvents() }
    }

    // Public method to start trace
    public func startTrace(topic: String) {
        eventsCollector.startTrace(topic: topic)
    }

    // Public method to save event
    public func saveEvent(_ event: TraceEvent) {
        eventsCollector.saveEvent(event)
    }

    // Public method to send stored events
    public func sendStoredEvents() async {
        let events = eventsCollector.storage.fetchErrorEvents()
        guard !events.isEmpty else { return }

        do {
            let success: Bool = try await eventsDispatcher.executeWithRetry(events: events)
            if success {
                self.eventsCollector.storage.clearErrorEvents()
            }
        } catch {
            logger.debug("Failed to send events after multiple attempts: \(error)")
        }
    }
}
