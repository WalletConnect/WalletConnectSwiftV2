
import Foundation

public enum NotificationScope: String, Hashable, Codable, CodingKeyRepresentable {
    case promotional
    case transactional
    case `private`
    case alerts
}
