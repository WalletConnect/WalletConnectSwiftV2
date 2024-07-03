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
    private let storage: EventStorage
    private let bundleId: String

    init(storage: EventStorage, bundleId: String) {
        self.storage = storage
        self.bundleId = bundleId
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
    func endTrace() {
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
        print("Error event saved: \(event)")
    }
}


#if DEBUG
class MockEventStorage: EventStorage {
    private(set) var savedEvents: [Event] = []

    func saveErrorEvent(_ event: Event) {
        savedEvents.append(event)
    }

    func fetchErrorEvents() -> [Event] {
        return savedEvents
    }

    func clearErrorEvents() {
        savedEvents.removeAll()
    }
}
#endif
