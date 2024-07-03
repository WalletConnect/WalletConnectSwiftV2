
import Foundation

class EventsClientFactory {
    static func createEventsClient(projectId: String, sdkType: String, sdkVersion: String, bundleId: String) -> EventsClient {
        let storage = UserDefaultsEventStorage()
        let networkingService = NetworkingService(projectId: projectId, sdkType: sdkType, sdkVersion: sdkVersion)
        return EventsClient(storage: storage, bundleId: bundleId, networkingService: networkingService)
    }
}
