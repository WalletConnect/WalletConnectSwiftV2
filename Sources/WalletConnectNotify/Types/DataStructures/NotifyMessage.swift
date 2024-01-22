import Foundation

public struct NotifyMessage: Codable, Equatable {
    public let id: String
    public let title: String
    public let body: String
    public let icon: String
    public let url: String
    public let type: String
    public let sent_at: UInt64

    public var sentAt: Date {
        return Date(milliseconds: sent_at)
    }

    public init(id: String, title: String, body: String, icon: String?, url: String?, type: String, sentAt: Date) {
        self.id = id
        self.title = title
        self.body = body
        self.icon = icon ?? ""
        self.url = url ?? ""
        self.type = type
        self.sent_at = UInt64(sentAt.millisecondsSince1970)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.body = try container.decode(String.self, forKey: .body)
        self.icon = try container.decodeIfPresent(String.self, forKey: .icon) ?? ""
        self.url = try container.decodeIfPresent(String.self, forKey: .url) ?? ""
        self.type = try container.decode(String.self, forKey: .type)
        self.sent_at = try container.decode(UInt64.self, forKey: .sent_at)
    }
}
