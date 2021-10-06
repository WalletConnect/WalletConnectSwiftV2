
import Foundation

extension SessionType {
    public struct DeleteParams: Codable, Equatable {
        public let reason: Reason
        public init(reason: SessionType.Reason) {
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
