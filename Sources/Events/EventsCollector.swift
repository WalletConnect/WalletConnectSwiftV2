import Foundation

// Protocol for TraceEvent
protocol TraceEvent: CustomStringConvertible {
    var description: String { get }
}

// Protocol for ErrorEvent
protocol ErrorEvent: TraceEvent {}


class EventsCollector {
    var trace: [String] = []
    var topic: String?
    let storage: EventStorage
    private let logger: ConsoleLogging
    private let bundleId: String

    init(
        storage: EventStorage,
        bundleId: String,
        logger: ConsoleLogging
    ) {
        self.storage = storage
        self.bundleId = bundleId
        self.logger = logger
    }

    // Function to start trace with topic
    func startTrace(topic: String) {
        self.topic = topic
        self.trace = []
    }

    // Function to save event
    func saveEvent(_ event: TraceEvent) {
        trace.append(event.description)
        if let errorEvent = event as? ErrorEvent {
            saveErrorEvent(errorEvent)
            endTrace()
        }
    }

    // Function to end trace
    private func endTrace() {
        self.topic = nil
        self.trace = []
    }

    // Private function to save error event
    private func saveErrorEvent(_ errorEvent: ErrorEvent) {
        let event = Event(
            eventId: UUID().uuidString,
            bundleId: bundleId,
            timestamp: Int64(Date().timeIntervalSince1970 * 1000),
            props: Props(
                event: "ERROR",
                type: errorEvent.description,
                properties: Properties(
                    topic: topic,
                    trace: trace
                )
            )
        )
        storage.saveErrorEvent(event)
        logger.debug("Error event saved: \(event)")
    }
}

