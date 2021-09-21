
import Foundation

extension SessionType {
    struct DeleteParams: Codable, Equatable {
        let topic: String
        let reason: Reason
        
        init(topic: String, reason: SessionType.Reason) {
            self.topic = topic
            self.reason = reason
        }
        
        init(_ params: DisconnectParams) {
            topic = params.topic
            reason = Reason(code: params.reason.code, message: params.reason.message)
        }
    }
    
    struct Reason: Codable, Equatable {
        let code: Int
        let message: String
    }
}
