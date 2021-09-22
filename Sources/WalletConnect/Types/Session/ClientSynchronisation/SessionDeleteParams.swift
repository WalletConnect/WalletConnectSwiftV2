
import Foundation

extension SessionType {
    public struct DeleteParams: Codable, Equatable {
        let topic: String
        let reason: Reason
        
        init(topic: String, reason: SessionType.Reason) {
            self.topic = topic
            self.reason = reason
        }
    }
    
    struct Reason: Codable, Equatable {
        let code: Int
        let message: String
    }
}
