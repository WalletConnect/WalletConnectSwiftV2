
import Foundation

extension PairingType {
    struct PayloadParams: Codable, Equatable {
        let request: Request
    }
    
}
extension PairingType.PayloadParams {
    struct Request: Codable, Equatable {
        let method: String
        let params: Params
    }
}

extension PairingType.PayloadParams.Request {
    enum Params: Codable, Equatable {
        init(from decoder: Decoder) throws {
            fatalError("not implemented")
        }
        
        func encode(to encoder: Encoder) throws {
            fatalError("not implemented")
        }
    }
}
