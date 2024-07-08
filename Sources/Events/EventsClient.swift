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
    private var telemetryEnabled: Bool

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
        self.telemetryEnabled = stateStorage.telemetryEnabled

        if telemetryEnabled {
            Task { await sendStoredEvents() }
        } else {
            self.eventsCollector.storage.clearErrorEvents()
        }
    }

    // Public method to start trace
    public func startTrace(topic: String) {
        guard telemetryEnabled else { return }
        eventsCollector.startTrace(topic: topic)
    }

    public func setTopic(_ topic: String) {
        guard telemetryEnabled else { return }
        eventsCollector.setTopic(topic)
    }

    // Public method to save event
    public func saveEvent(_ event: TraceEvent) {
        guard telemetryEnabled else { return }
        eventsCollector.saveEvent(event)
    }

    // Public method to set telemetry enabled or disabled
    public func setTelemetryEnabled(_ enabled: Bool) {
        telemetryEnabled = enabled
        stateStorage.telemetryEnabled = enabled
        if enabled {
            Task { await sendStoredEvents() }
        } else {
            eventsCollector.storage.clearErrorEvents()
        }
    }

    private func sendStoredEvents() async {
        guard telemetryEnabled else { return }
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
