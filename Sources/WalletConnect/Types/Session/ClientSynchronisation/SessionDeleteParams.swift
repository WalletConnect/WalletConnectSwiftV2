
import Foundation

extension SessionType {
    struct DeleteParams: Codable, Equatable {
        let reason: Reason
        init(reason: SessionType.Reason) {
            self.reason = reason
        }
    }
    
    struct Reason: Codable, Equatable {
        let code: Int
        let message: String
        
        init(code: Int, message: String) {
            self.code = code
            self.message = message
        }
    }
}

// A better solution could fit in here
internal extension Reason {
    func toInternal() -> SessionType.Reason {
        SessionType.Reason(code: self.code, message: self.message)
    }
}

extension SessionType.Reason {
    func toPublic() -> Reason {
        Reason(code: self.code, message: self.message)
    }
}
