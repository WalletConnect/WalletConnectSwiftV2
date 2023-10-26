import Foundation
import Database

public struct NotifySubscription: DatabaseObject, SqliteRow {
    public let topic: String
    public let account: Account
    public let relay: RelayProtocolOptions
    public let metadata: AppMetadata
    public let scope: [String: ScopeValue]
    public let expiry: Date
    public let symKey: String
    public let appAuthenticationKey: String

    public var databaseId: String {
        return topic
    }

    public init(decoder: SqliteRowDecoder) throws {
        self.topic = try decoder.decodeString(at: 0)
        self.account = try Account(decoder.decodeString(at: 1))!
        self.relay = try decoder.decodeCodable(at: 2)
        self.metadata = try decoder.decodeCodable(at: 3)
        self.scope = try decoder.decodeCodable(at: 4)
        self.expiry = try decoder.decodeDate(at: 5)
        self.symKey = try decoder.decodeString(at: 6)
    }

    public func encode() -> SqliteRowEncoder {
        var encoder = SqliteRowEncoder()
        encoder.encodeString(topic, for: "topic")
        encoder.encodeString(account.absoluteString, for: "account")
        encoder.encodeCodable(relay, for: "relay")
        encoder.encodeCodable(metadata, for: "metadata")
        encoder.encodeCodable(scope, for: "scope")
        encoder.encodeDate(expiry, for: "expiry")
        encoder.encodeString(symKey, for: "symKey")
        return encoder
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
