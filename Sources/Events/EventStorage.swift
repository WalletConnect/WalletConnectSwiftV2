
import Foundation

protocol EventStorage {
    func saveErrorEvent(_ event: TraceEvent)
    func fetchErrorEvents() -> [TraceEvent]
    func clearErrorEvents()
}

class UserDefaultsTraceEventStorage: EventStorage {
    private let errorEventsKey = "com.walletconnect.sdk.errorEvents"
    private let maxEvents = 30

    func saveErrorEvent(_ event: TraceEvent) {
        var existingEvents = fetchErrorEvents()
        existingEvents.append(event)
        // Ensure we keep only the last 30 events
        if existingEvents.count > maxEvents {
            existingEvents = Array(existingEvents.suffix(maxEvents))
        }
        if let encoded = try? JSONEncoder().encode(existingEvents) {
            UserDefaults.standard.set(encoded, forKey: errorEventsKey)
        }
    }

    func fetchErrorEvents() -> [TraceEvent] {
        if let data = UserDefaults.standard.data(forKey: errorEventsKey),
           let events = try? JSONDecoder().decode([TraceEvent].self, from: data) {
            // Return only the last 30 events
            return Array(events.suffix(maxEvents))
        }
        return []
    }

    func clearErrorEvents() {
        UserDefaults.standard.removeObject(forKey: errorEventsKey)
    }
}

#if DEBUG
class MockEventStorage: EventStorage {
    private(set) var savedEvents: [TraceEvent] = []

    func saveErrorEvent(_ event: TraceEvent) {
        savedEvents.append(event)
    }

    func fetchErrorEvents() -> [TraceEvent] {
        return savedEvents
    }

    func clearErrorEvents() {
        savedEvents.removeAll()
    }
}
#endif

