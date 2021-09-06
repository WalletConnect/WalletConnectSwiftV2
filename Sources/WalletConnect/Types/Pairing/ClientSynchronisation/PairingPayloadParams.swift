
import Foundation

extension PairingType {
    struct PayloadParams: Codable {
        let request: Request
    }
    
}
extension PairingType.PayloadParams {
    struct Request: Codable {
        let method: String
        let params: Params
    }
}

extension PairingType.PayloadParams.Request {
    enum Params: Codable {
        init(from decoder: Decoder) throws {
            fatalError("not implemented")
        }
        
        func encode(to encoder: Encoder) throws {
            fatalError("not implemented")
        }
    }
}
