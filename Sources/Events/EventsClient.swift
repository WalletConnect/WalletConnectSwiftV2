import Foundation

public protocol EventsClientProtocol {
    func startTrace(topic: String)
    func saveTraceEvent(_ event: TraceEventItem)
    func setTopic(_ topic: String)
    func setTelemetryEnabled(_ enabled: Bool)
    func saveMessageEvent(_ event: MessageEventType)
}

public class EventsClient: EventsClientProtocol {
    private let eventsCollector: EventsCollector
    private let eventsDispatcher: EventsDispatcher
    private let logger: ConsoleLogging
    private var stateStorage: TelemetryStateStorage
    private let messageEventsStorage: MessageEventsStorage

    init(
        eventsCollector: EventsCollector,
        eventsDispatcher: EventsDispatcher,
        logger: ConsoleLogging,
        stateStorage: TelemetryStateStorage,
        messageEventsStorage: MessageEventsStorage
    ) {
        self.eventsCollector = eventsCollector
        self.eventsDispatcher = eventsDispatcher
        self.logger = logger
        self.stateStorage = stateStorage
        self.messageEventsStorage = messageEventsStorage

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
    public func saveTraceEvent(_ event: TraceEventItem) {
        guard stateStorage.telemetryEnabled else { return }
        logger.debug("Will store a trace event: \(event)")
        eventsCollector.saveEvent(event)
    }

    public func saveMessageEvent(_ event: MessageEventType) {
        logger.debug("Will store a message event: \(event)")
        messageEventsStorage.saveMessageEvent(event)
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

        let traceEvents = eventsCollector.storage.fetchErrorEvents()
        let messageEvents = messageEventsStorage.fetchMessageEvents()

        guard !traceEvents.isEmpty || !messageEvents.isEmpty else { return }

        var combinedEvents: [AnyCodable] = []

        // Wrap trace events
        combinedEvents.append(contentsOf: traceEvents.map { AnyCodable($0) })

        // Wrap message events
        combinedEvents.append(contentsOf: messageEvents.map { AnyCodable($0) })

        logger.debug("Will send combined events")
        do {
            let success: Bool = try await eventsDispatcher.executeWithRetry(events: combinedEvents)
            if success {
                logger.debug("Combined events sent successfully")
                self.eventsCollector.storage.clearErrorEvents()
                self.messageEventsStorage.clearMessageEvents()
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

    public func saveTraceEvent(_ event: TraceEventItem) {
        saveEventCalled = true
    }

    public func setTelemetryEnabled(_ enabled: Bool) {
        telemetryEnabled = enabled
    }

    public func saveMessageEvent(_ event: MessageEventType) {

    }

}
#endif
