import Foundation

class EventsClientFactory {
    static func createEventsClient(
        projectId: String,
        sdkType: String,
        sdkVersion: String,
        bundleId: String
    ) -> EventsClient {
        let storage = UserDefaultsEventStorage()
        let networkingService = NetworkingService(
            projectId: projectId,
            sdkType: sdkType,
            sdkVersion: sdkVersion
        )
        let logger = ConsoleLogger(prefix: "", loggingLevel: .off)
        let retryPolicy = RetryPolicy(maxAttempts: 3, initialDelay: 5, multiplier: 2)
        let eventsDispatcher = EventsDispatcher(networkingService: networkingService, retryPolicy: retryPolicy)
        let eventsCollector = EventsCollector(storage: storage, bundleId: bundleId, logger: logger)
        return EventsClient(
            eventsCollector: eventsCollector,
            eventsDispatcher: eventsDispatcher,
            logger: logger
        )
    }
}
