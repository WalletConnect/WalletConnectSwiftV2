
import Foundation

extension SessionType {
    public struct DeleteParams: Codable, Equatable {
        public let topic: String
        public let reason: Reason
        
        public init(topic: String, reason: SessionType.Reason) {
            self.topic = topic
            self.reason = reason
        }
    }
    
    public struct Reason: Codable, Equatable {
        public let code: Int
        public let message: String
        
        public init(code: Int, message: String) {
            self.code = code
            self.message = message
        }
    }
}
