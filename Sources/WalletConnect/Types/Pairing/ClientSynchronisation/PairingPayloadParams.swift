
import Foundation

struct PairingPayloadParams: Codable {
    let request: Request
}

extension PairingPayloadParams {
    struct Request: Codable {
        let method: String
        let params: Params
    }
}

extension PairingPayloadParams.Request {
    enum Params: Codable {
        init(from decoder: Decoder) throws {
            fatalError("not implemented")
        }
        
        func encode(to encoder: Encoder) throws {
            fatalError("not implemented")
        }
    }
}
