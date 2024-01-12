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
        return Date(timeIntervalSince1970: TimeInterval(sent_at))
    }

    public init(id: String, title: String, body: String, icon: String, url: String, type: String, sentAt: Date) {
        self.id = id
        self.title = title
        self.body = body
        self.icon = icon
        self.url = url
        self.type = type
        self.sent_at = UInt64(sentAt.timeIntervalSince1970)
    }
}
