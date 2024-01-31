import Foundation
import Database

public struct NotifySubscription: Codable, Equatable, SqliteRow {
    public let topic: String
    public let account: Account
    public let relay: RelayProtocolOptions
    public let metadata: AppMetadata
    public let scope: [String: ScopeValue]
    public let expiry: Date
    public let symKey: String
    public let appAuthenticationKey: String

    private var id: String {
        return "\(account.absoluteString)-\(metadata.url)"
    }

    public func messageIcons(ofType type: String) -> NotifyImageUrls {
        return scope[type]?.imageUrls ?? NotifyImageUrls(icons: metadata.icons) ?? NotifyImageUrls()
    }

    public init(decoder: SqliteRowDecoder) throws {
        self.topic = try decoder.decodeString(at: 0)
        self.account = try Account(decoder.decodeString(at: 1))!
        self.relay = try decoder.decodeCodable(at: 2)
        self.metadata = try decoder.decodeCodable(at: 3)
        self.scope = try decoder.decodeCodable(at: 4)
        self.expiry = try decoder.decodeDate(at: 5)
        self.symKey = try decoder.decodeString(at: 6)
        self.appAuthenticationKey = try decoder.decodeString(at: 7)
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
        encoder.encodeString(appAuthenticationKey, for: "appAuthenticationKey")
        encoder.encodeString(id, for: "id")
        return encoder
    }

    init(topic: String, account: Account, relay: RelayProtocolOptions, metadata: AppMetadata, scope: [String : ScopeValue], expiry: Date, symKey: String, appAuthenticationKey: String) {
        self.topic = topic
        self.account = account
        self.relay = relay
        self.metadata = metadata
        self.scope = scope
        self.expiry = expiry
        self.symKey = symKey
        self.appAuthenticationKey = appAuthenticationKey
    }

    init(subscription: NotifySubscription, scope: [String : ScopeValue], expiry: Date) {
        self.topic = subscription.topic
        self.account = subscription.account
        self.relay = subscription.relay
        self.metadata = subscription.metadata
        self.symKey = subscription.symKey
        self.appAuthenticationKey = subscription.appAuthenticationKey
        self.scope = scope
        self.expiry = expiry
    }
}

public struct ScopeValue: Codable, Equatable {
    public let id: String
    public let name: String
    public let description: String
    public let imageUrls: NotifyImageUrls?
    public let enabled: Bool

    public init(id: String, name: String, description: String, imageUrls: NotifyImageUrls?, enabled: Bool) {
        self.id = id
        self.name = name
        self.description = description
        self.imageUrls = imageUrls
        self.enabled = enabled
    }
}
