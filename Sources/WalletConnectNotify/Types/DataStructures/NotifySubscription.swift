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
    public let id: String
    public let name: String
    public let description: String
    public let enabled: Bool

    public init(id: String, name: String, description: String, enabled: Bool) {
        self.id = id
        self.name = name
        self.description = description
        self.enabled = enabled
    }
}
