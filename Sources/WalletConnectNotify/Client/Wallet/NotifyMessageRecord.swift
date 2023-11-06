import Foundation

public struct NotifyMessageRecord: Codable, Equatable, SqliteRow {
    public let id: String
    public let topic: String
    public let message: NotifyMessage
    public let publishedAt: Date

    public var databaseId: String {
        return id
    }

    public init(id: String, topic: String, message: NotifyMessage, publishedAt: Date) {
        self.id = id
        self.topic = topic
        self.message = message
        self.publishedAt = publishedAt
    }

    public init(decoder: SqliteRowDecoder) throws {
        self.id = try decoder.decodeString(at: 0)
        self.topic = try decoder.decodeString(at: 1)

        self.message = NotifyMessage(
            title: try decoder.decodeString(at: 2),
            body: try decoder.decodeString(at: 3),
            icon: try decoder.decodeString(at: 4),
            url: try decoder.decodeString(at: 5),
            type: try decoder.decodeString(at: 6)
        )

        self.publishedAt = try decoder.decodeDate(at: 7)
    }

    public func encode() -> SqliteRowEncoder {
        var encoder = SqliteRowEncoder()
        encoder.encodeString(id, for: "id")
        encoder.encodeString(topic, for: "topic")
        encoder.encodeString(message.title, for: "title")
        encoder.encodeString(message.body, for: "body")
        encoder.encodeString(message.icon, for: "icon")
        encoder.encodeString(message.url, for: "url")
        encoder.encodeString(message.type, for: "type")
        encoder.encodeDate(publishedAt, for: "publishedAt")
        return encoder
    }
}
