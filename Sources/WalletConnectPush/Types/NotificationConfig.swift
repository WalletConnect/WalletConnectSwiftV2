
import Foundation

struct NotificationConfig: Codable {
    let version: Int
    let lastModified: TimeInterval
    let types: [NotificationType]

}
