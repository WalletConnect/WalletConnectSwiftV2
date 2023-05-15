import Foundation

public struct PushMessage: Codable, Equatable {
    public let title: String
    public let body: String
    public let icon: String
    public let url: String
    public let type: String?

    public init(title: String, body: String, icon: String, url: String, type: String? = nil) {
        self.title = title
        self.body = body
        self.icon = icon
        self.url = url
        self.type = type
    }
}
