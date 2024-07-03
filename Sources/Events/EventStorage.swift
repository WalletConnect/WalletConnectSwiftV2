//     

import Foundation


// Protocol for EventStorage
protocol EventStorage {
    func saveErrorEvent(_ event: Event)
    func fetchErrorEvents() -> [Event]
    func clearErrorEvents()
}

// Default implementation using UserDefaults
class UserDefaultsEventStorage: EventStorage {
    private let errorEventsKey = "com.walletconnect.sdk.errorEvents"

    func saveErrorEvent(_ event: Event) {
        var existingEvents = fetchErrorEvents()
        existingEvents.append(event)
        if let encoded = try? JSONEncoder().encode(existingEvents) {
            UserDefaults.standard.set(encoded, forKey: errorEventsKey)
        }
    }

    func fetchErrorEvents() -> [Event] {
        if let data = UserDefaults.standard.data(forKey: errorEventsKey),
           let events = try? JSONDecoder().decode([Event].self, from: data) {
            return events
        }
        return []
    }

    func clearErrorEvents() {
        UserDefaults.standard.removeObject(forKey: errorEventsKey)
    }
}
