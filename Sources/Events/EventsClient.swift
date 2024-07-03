import Foundation


import Foundation

class EventsClientFactory {
    static func createEventsClient(projectId: String, sdkType: String, sdkVersion: String, bundleId: String) -> EventsClient {
        let storage = UserDefaultsEventStorage()
        let networkingService = NetworkingService(projectId: projectId, sdkType: sdkType, sdkVersion: sdkVersion)
        return EventsClient(storage: storage, bundleId: bundleId, networkingService: networkingService)
    }
}
class EventsClient {
    private let eventsCollector: EventsCollector
    private let eventsDispatcher: EventsDispatcher

    init(storage: EventStorage, bundleId: String, networkingService: NetworkingServiceProtocol) {
        self.eventsCollector = EventsCollector(storage: storage, bundleId: bundleId)
        let retryPolicy = RetryPolicy(maxAttempts: 3, initialDelay: 5, multiplier: 2)
        self.eventsDispatcher = EventsDispatcher(networkingService: networkingService, retryPolicy: retryPolicy)
        Task { await sendStoredEvents() }
    }

    // Public method to start trace
    public func startTrace(topic: String) {
        eventsCollector.startTrace(topic: topic)
    }

    // Public method to save event
    public func saveEvent(_ event: TraceEvent) {
        eventsCollector.saveEvent(event)
    }

    // Public method to send stored events
    private func sendStoredEvents() async {
        let events = eventsCollector.storage.fetchErrorEvents()
        guard !events.isEmpty else { return }

        do {
            let success: Bool = try await eventsDispatcher.executeWithRetry(events: events)
            if success {
                self.eventsCollector.storage.clearErrorEvents()
            }
        } catch {
            print("Failed to send events after multiple attempts: \(error)")
        }
    }
}

