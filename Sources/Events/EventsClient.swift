import Foundation

// Protocol for TraceEvent
protocol TraceEvent: CustomStringConvertible {
    var description: String { get }
}

// Protocol for ErrorEvent
protocol ErrorEvent: TraceEvent {}


// EventsCollector Class
class EventsCollector {
    private var trace: [String] = []
    private var topic: String?
    private let storage: EventStorage

    init(storage: EventStorage) {
        self.storage = storage
    }

    // Function to start trace with topic
    func startTrace(topic: String) {
        self.topic = topic
        self.trace = []
    }

    // Function to save event
    func saveEvent(_ event: TraceEvent) {
        trace.append(event.description)
        if event is ErrorEvent {
            saveErrorTrace()
            endTrace()
        }
    }

    // Function to end trace
    func endTrace() {
        self.topic = nil
        self.trace = []
    }

    // Private function to save error trace
    private func saveErrorTrace() {
        storage.saveErrorTrace(trace)
        print("Error trace saved: \(trace)")
    }
}
