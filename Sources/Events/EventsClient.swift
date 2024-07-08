import Foundation

public protocol EventsClientProtocol {
    func startTrace(topic: String)
    func saveEvent(_ event: TraceEvent)
    func setTopic(_ topic: String)
    func setTelemetryEnabled(_ enabled: Bool)
}

public class EventsClient: EventsClientProtocol {
    private let eventsCollector: EventsCollector
    private let eventsDispatcher: EventsDispatcher
    private let logger: ConsoleLogging
    private var stateStorage: TelemetryStateStorage

    init(
        eventsCollector: EventsCollector,
        eventsDispatcher: EventsDispatcher,
        logger: ConsoleLogging,
        stateStorage: TelemetryStateStorage
    ) {
        self.eventsCollector = eventsCollector
        self.eventsDispatcher = eventsDispatcher
        self.logger = logger
        self.stateStorage = stateStorage

        if stateStorage.telemetryEnabled {
            Task { await sendStoredEvents() }
        } else {
            self.eventsCollector.storage.clearErrorEvents()
        }
    }

    public func setLogging(level: LoggingLevel) {
        logger.setLogging(level: level)
    }

    // Public method to start trace
    public func startTrace(topic: String) {
        guard stateStorage.telemetryEnabled else { return }
        logger.debug("Will start trace with topic: \(topic)")
        eventsCollector.startTrace(topic: topic)
    }

    public func setTopic(_ topic: String) {
        guard stateStorage.telemetryEnabled else { return }
        eventsCollector.setTopic(topic)
    }

    // Public method to save event
    public func saveEvent(_ event: TraceEvent) {
        guard stateStorage.telemetryEnabled else { return }
        logger.debug("Will store an event: \(event)")
        eventsCollector.saveEvent(event)
    }

    // Public method to set telemetry enabled or disabled
    public func setTelemetryEnabled(_ enabled: Bool) {
        stateStorage.telemetryEnabled = enabled
        if enabled {
            Task { await sendStoredEvents() }
        } else {
            eventsCollector.storage.clearErrorEvents()
        }
    }

    private func sendStoredEvents() async {
        guard stateStorage.telemetryEnabled else { return }
        let events = eventsCollector.storage.fetchErrorEvents()
        guard !events.isEmpty else { return }

        logger.debug("Will send events")
        do {
            let success: Bool = try await eventsDispatcher.executeWithRetry(events: events)
            if success {
                logger.debug("Events sent successfully")
                self.eventsCollector.storage.clearErrorEvents()
            }
        } catch {
            logger.debug("Failed to send events after multiple attempts: \(error)")
        }
    }
}

#if DEBUG
public class MockEventsClient: EventsClientProtocol {
    var startTraceCalled = false
    var saveEventCalled = false
    var telemetryEnabled = true

    public init() {}

    public func startTrace(topic: String) {
        startTraceCalled = true
    }

    public func setTopic(_ topic: String) {}

    public func saveEvent(_ event: TraceEvent) {
        saveEventCalled = true
    }

    public func setTelemetryEnabled(_ enabled: Bool) {
        telemetryEnabled = enabled
    }
}
#endif
