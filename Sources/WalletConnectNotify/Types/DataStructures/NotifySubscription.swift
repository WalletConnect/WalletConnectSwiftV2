import Foundation

public struct NotifySubscription: DatabaseObject {
    public let topic: String
    public let account: Account
    public let relay: RelayProtocolOptions
    public let metadata: AppMetadata
    public let scope: [String: ScopeValue]
    public let expiry: Date
    public let symKey: String

    public var databaseId: String {
        return topic
    }
}

public struct ScopeValue: Codable, Equatable {
    public let description: String
    public let enabled: Bool

    public init(description: String, enabled: Bool) {
        self.description = description
        self.enabled = enabled
    }
}
