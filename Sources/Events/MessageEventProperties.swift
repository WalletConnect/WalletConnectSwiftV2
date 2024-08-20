
import Foundation

public struct MessageEventProperties {
    let tag: Int
    let rpcId: RPCID
}

struct MessageEvent: Codable {
    struct Props: Codable {
        let event: String = "SUCCESS"
        let type: String
        let properties: Properties
    }

    struct Properties: Codable {
        let correlationId: Int64
        let clientId: String

        // Custom CodingKeys to map Swift property names to JSON keys
        enum CodingKeys: String, CodingKey {
            case correlationId = "correlation_id"
            case clientId = "client_id"
        }
    }

    let eventId: String
    let bundleId: String
    let timestamp: Int64
    let props: Props
}



protocol MessageEventsStorage {
    func saveMessageEvent(_ event: MessageEventProperties)
    func fetchMessageEvents() -> [MessageEvent]
    func clearMessageEvents()
}

class UserDefaultsMessageEventsStorage: MessageEventsStorage {
    private let messageEventsKey = "com.walletconnect.sdk.messageEvents"
    private let maxEvents = 200

    func saveMessageEvent(_ event: MessageEventProperties) {
        // Create the correlation_id from rpcId
        let correlationId = event.rpcId.integer

        let type = "\(event.tag)"

        let bundleId = Bundle.main.bundleIdentifier ?? "Unknown"

        let props = MessageEvent.Props(
            type: type,
            properties: MessageEvent.Properties(
                correlationId: correlationId,
                clientId: bundleId
            )
        )

        let eventObject = MessageEvent(
            eventId: UUID().uuidString,
            bundleId: bundleId,
            timestamp: Int64(Date().timeIntervalSince1970 * 1000),
            props: props
        )

        // Fetch existing events from UserDefaults
        var existingEvents = fetchMessageEvents()
        existingEvents.append(eventObject)

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
            return events
        }
        return []
    }

    func clearMessageEvents() {
        UserDefaults.standard.removeObject(forKey: messageEventsKey)
    }
}
