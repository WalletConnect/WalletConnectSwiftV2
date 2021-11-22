
import Foundation

extension PairingType {
    struct PayloadParams: Codable, Equatable {
        let request: Request
    }
    
}
extension PairingType.PayloadParams {
    struct Request: Codable, Equatable {
        let method: PairingType.PayloadMethods
        let params: SessionType.ProposeParams
    }
}
