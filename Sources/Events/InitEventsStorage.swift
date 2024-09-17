import Foundation

protocol InitEventsStorage {
    func saveInitEvent(_ event: InitEvent)
    func fetchInitEvents() -> [InitEvent]
    func clearInitEvents()
}


class UserDefaultsInitEventsStorage: InitEventsStorage {
    private let initEventsKey = "com.walletconnect.sdk.initEvents"
    private let maxEvents = 100

    func saveInitEvent(_ event: InitEvent) {
        // Fetch existing events from UserDefaults
        var existingEvents = fetchInitEvents()
        existingEvents.append(event)

        // Ensure we keep only the last 100 events
        if existingEvents.count > maxEvents {
            existingEvents = Array(existingEvents.suffix(maxEvents))
        }

        // Save updated events back to UserDefaults
        if let encoded = try? JSONEncoder().encode(existingEvents) {
            UserDefaults.standard.set(encoded, forKey: initEventsKey)
        }
    }

    func fetchInitEvents() -> [InitEvent] {
        if let data = UserDefaults.standard.data(forKey: initEventsKey),
           let events = try? JSONDecoder().decode([InitEvent].self, from: data) {
            // Return only the last 100 events
            return Array(events.suffix(maxEvents))
        }
        return []
    }

    func clearInitEvents() {
        UserDefaults.standard.removeObject(forKey: initEventsKey)
    }
}
