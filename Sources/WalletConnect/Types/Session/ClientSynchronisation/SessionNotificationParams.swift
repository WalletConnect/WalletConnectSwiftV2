
import Foundation
import WalletConnectUtils

//public typealias SessionNotification = SessionType.NotificationParams

extension SessionType {
    struct NotificationParams: Codable, Equatable {
        let type: String
        let data: AnyCodable
        
        init(type: String, data: AnyCodable) {
            self.type = type
            self.data = data
        }
    }
}
