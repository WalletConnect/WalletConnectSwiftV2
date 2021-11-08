
import Foundation

extension SessionType {
    public struct NotificationParams: Codable, Equatable {
        let type: String
        let data: AnyCodable
    }
}
