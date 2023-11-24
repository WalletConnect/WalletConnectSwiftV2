import Foundation

public struct NotifyMessage: Codable, Equatable {
    public let id: String
    public let title: String
    public let body: String
    public let icon: String
    public let url: String
    public let type: String

    public init(id: String, title: String, body: String, icon: String, url: String, type: String) {
        self.id = id
        self.title = title
        self.body = body
        self.icon = icon
        self.url = url
        self.type = type
    }
}
