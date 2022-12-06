
import Foundation

public struct PushMessage: Codable {
    let title: String
    let body: String
    let icon: String
    let url: String

    public init(title: String, body: String, icon: String, url: String) {
        self.title = title
        self.body = body
        self.icon = icon
        self.url = url
    }
}
