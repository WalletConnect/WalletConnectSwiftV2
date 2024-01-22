import Foundation

public struct NotifyMessageRecord: Codable, Equatable, SqliteRow {
    public let topic: String
    public let message: NotifyMessage
    public let publishedAt: Date

    public var id: String {
        return message.id
    }

    public init(topic: String, message: NotifyMessage, publishedAt: Date) {
        self.topic = topic
        self.message = message
        self.publishedAt = publishedAt
    }

    public init(decoder: SqliteRowDecoder) throws {
        self.topic = try decoder.decodeString(at: 1)

        let sentAt = try decoder.decodeDate(at: 7)

        self.message = NotifyMessage(
            id: try decoder.decodeString(at: 0),
            title: try decoder.decodeString(at: 2),
            body: try decoder.decodeString(at: 3),
            icon: try decoder.decodeString(at: 4),
            url: try decoder.decodeString(at: 5),
            type: try decoder.decodeString(at: 6), 
            sentAt: sentAt
        )

        self.publishedAt = sentAt
    }

    public func encode() -> SqliteRowEncoder {
        var encoder = SqliteRowEncoder()
        encoder.encodeString(message.id, for: "id")
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
