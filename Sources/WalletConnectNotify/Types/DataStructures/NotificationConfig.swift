
import Foundation

struct NotificationConfig: Codable {
    let schemaVersion: Int
    let name: String
    let description: String
    let icons: [String]
    let types: [NotificationType]
}
