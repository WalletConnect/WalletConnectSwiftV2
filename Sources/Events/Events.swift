import Foundation

public class Events {
    /// Singleton instance of EventsClient
    public static var instance: EventsClient = {
        return EventsClientFactory.create(
            projectId: Networking.projectId,
            sdkVersion: EnvironmentInfo.sdkName
        )
    }()
}
