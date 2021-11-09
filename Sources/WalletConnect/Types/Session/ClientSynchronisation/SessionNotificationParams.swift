
import Foundation
public typealias Notification = SessionType.NotificationParams

extension SessionType {
    public struct NotificationParams: Codable, Equatable {
        let type: String
        let data: AnyCodable
        
        public init(type: String, data: AnyCodable) {
            self.type = type
            self.data = data
        }
    }
}
