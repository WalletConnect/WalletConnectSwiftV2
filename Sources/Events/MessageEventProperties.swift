import Foundation

protocol MessageEventsStorage {
    func saveMessageEvent(_ eventType: MessageEventType)
    func fetchMessageEvents() -> [MessageEvent] 
    func clearMessageEvents() 
}

class UserDefaultsMessageEventsStorage: MessageEventsStorage {
    private let messageEventsKey = "com.walletconnect.sdk.messageEvents"
    private let maxEvents = 200

    func saveMessageEvent(_ eventType: MessageEventType) {
        let correlationId = eventType.rpcId.integer
        let type = "\(eventType.tag)"
        let bundleId = Bundle.main.bundleIdentifier ?? "Unknown"
        let clientId = (try? Networking.interactor.getClientId()) ?? "Unknown"

        let props = MessageEvent.Props(
            type: type,
            properties: MessageEvent.Properties(
                correlationId: correlationId,
                clientId: clientId,
                direction: eventType.direction
            )
        )

        let event = MessageEvent(
            eventId: UUID().uuidString,
            bundleId: bundleId,
            timestamp: Int64(Date().timeIntervalSince1970 * 1000),
            props: props
        )

        // Fetch existing events from UserDefaults
        var existingEvents = fetchMessageEvents()
        existingEvents.append(event)

        // Ensure we keep only the last 200 events
        if existingEvents.count > maxEvents {
            existingEvents = Array(existingEvents.suffix(maxEvents))
        }

        // Save updated events back to UserDefaults
        if let encoded = try? JSONEncoder().encode(existingEvents) {
            UserDefaults.standard.set(encoded, forKey: messageEventsKey)
        }
    }

    func fetchMessageEvents() -> [MessageEvent] {
        if let data = UserDefaults.standard.data(forKey: messageEventsKey),
           let events = try? JSONDecoder().decode([MessageEvent].self, from: data) {
            // Return only the last 200 events
            return Array(events.suffix(maxEvents))
        }
        return []
    }

    func clearMessageEvents() {
        UserDefaults.standard.removeObject(forKey: messageEventsKey)
    }
}
