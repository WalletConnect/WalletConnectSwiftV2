
import Foundation

public enum NotificationScope: String, Hashable, Codable, CodingKeyRepresentable, CaseIterable {
    case promotional
    case transactional
    case `private`
    case alerts
}
